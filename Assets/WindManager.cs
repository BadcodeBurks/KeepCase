using System;
using System.Collections;
using UnityEngine;
using Random = UnityEngine.Random;

public class WindManager : MonoBehaviour
{
    [SerializeField]private Transform islandPivot;
    [SerializeField]private Transform windParent;
    [SerializeField]private float pivotDistance;
    [SerializeField]private ParticleSystem smoothWind;
    [SerializeField]private ParticleSystem spinningWind;
    [SerializeField]private ParticleSystemForceField forceField;
    [SerializeField] private Rigidbody boxRb;
    
    private int _windDirectionID;
    private int _noisePowerID;
    private int _noiseTimeScaleID;
    
    private Vector3 _windDirection;

    private bool _changingDirection = false;
    
    void Awake()
    {
        _windDirection = Vector3.forward;
        _windDirectionID = Shader.PropertyToID("_WindDirection");
        _noisePowerID = Shader.PropertyToID("_NoisePower");
        _noiseTimeScaleID = Shader.PropertyToID("_NoiseTimeScale");
        Shader.SetGlobalVector(_windDirectionID, new Vector4(1.0f, 0.0f, 0.0f, 0.0f));
        Shader.SetGlobalFloat(_noisePowerID, 1.0f);
        Shader.SetGlobalFloat(_noiseTimeScaleID, .6f);
        _changingDirection = false;
    }
    
    private void SetWindDirection(Vector3 direction)
    {
        if (_changingDirection) return;
        _windDirection = direction;
        StartCoroutine(ChangeWindDirection(direction));
        windParent.position = islandPivot.position - direction * pivotDistance;
        windParent.LookAt(islandPivot);
        windParent.position = new Vector3(windParent.position.x, 6, windParent.position.z);
        forceField.directionX = direction.x * 40;
        forceField.directionY = direction.y * 40;
        forceField.directionZ = direction.z * 40;
        smoothWind.Play();
        spinningWind.Play();
        StartCoroutine(ApplyWind(direction));
        //TODO: physics to box
        //TODO: wind sound
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Vector3 randomDir = Quaternion.Euler(0, Random.Range(0f, 200f), 0) * _windDirection;
            SetWindDirection(randomDir);
        }
    }

    private IEnumerator ChangeWindDirection(Vector3 targetWindDirection)
    {
        _changingDirection = true;
        Vector3 currentWindDirection = Shader.GetGlobalVector(_windDirectionID);
        Vector3 previousWindDirection = currentWindDirection;
        float t = 0;
        float duration = .6f;
        while (t<duration)
        {
            currentWindDirection = Vector3.Lerp(previousWindDirection, targetWindDirection, t/duration);
            SetWindDirection(currentWindDirection);
            yield return new WaitForEndOfFrame();
            t+=Time.deltaTime;
        }

        yield return new WaitForSeconds(2.4f);
        _changingDirection = false;
    }

    private IEnumerator ApplyWind(Vector3 direction)
    {
        float t = 0;
        direction = GetForceDirection(direction);
        while (t < 1.5f)
        {
            boxRb.AddForce(direction * 6);
            yield return new WaitForFixedUpdate();
            t+=Time.fixedDeltaTime;
        }
    }

    private Vector3 GetForceDirection(Vector3 direction)
    {
        float gravityLoosenFactor = 1.03f;
        Transform boxTransform = boxRb.transform;
        Vector3 forceDir = direction - Vector3.Dot(direction, boxTransform.up) * boxTransform.up;
        forceDir.Normalize();
        return forceDir + gravityLoosenFactor * boxTransform.up;
    }
}
