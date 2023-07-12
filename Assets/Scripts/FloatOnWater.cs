using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FloatOnWater : MonoBehaviour
{
    [SerializeField]private TrailController trailController;
    [SerializeField]private Animator resetButtonAnimator;
    public const float waterLevel = 0.0f;
    public const float floatHeight = .5f;

    public Rigidbody rb;
    public bool onWater = false;
    private Vector3 _startPos;
    private Quaternion _startRot;
    private bool _isResetting;

    private void Start()
    {
        _isResetting = false;
        _startPos = transform.position;
        _startRot = transform.rotation;
        trailController.TurnOnTrail();
    }

    private void FixedUpdate()
    {
        if(_isResetting) return;
        float boxPos = rb.position.y;
        if (!onWater)
        {
            if(boxPos < waterLevel + floatHeight)
            {
                OnFallInWater();
            }

            return;
        }
        rb.AddForce(0, (-boxPos +floatHeight) * 40, 0);
    }

    private void Update()
    {
        if(_isResetting) return;
        if(!onWater) return;
        if (Input.GetKeyDown(KeyCode.R))
        {
            ResetPos();
        }
    }

    public void OnFallInWater()
    {
        onWater = true;
        rb.drag = 0.5f;
        rb.angularDrag = 0.5f;
        resetButtonAnimator.Play("FadeRIn");
    }
    
    public void ResetPos()
    {
        StartCoroutine(ResetPosR());
    }

    public IEnumerator ResetPosR()
    {
        _isResetting = true;
        resetButtonAnimator.Play("FadeROut");
        float t = 0;
        float shrinkDuration = .3f;
        rb.isKinematic = true;
        while(t < shrinkDuration)
        {
            t += Time.deltaTime;
            transform.localScale = Vector3.Lerp(Vector3.one, Vector3.one * .001f, Mathf.Pow(t / shrinkDuration, 2));
            yield return new WaitForEndOfFrame();
        }
        rb.position = _startPos;
        rb.rotation = _startRot;
        rb.drag = 0;
        rb.angularDrag = 0.05f;
        rb.velocity = Vector3.zero;
        rb.angularVelocity = Vector3.zero;
        onWater = false;
        trailController.TurnOffTrail();
        t = 0;
        while(t < shrinkDuration)
        {
            t += Time.deltaTime;
            transform.localScale = Vector3.Lerp(Vector3.one * .001f, Vector3.one, Mathf.Pow(t / shrinkDuration, 2));
            yield return new WaitForEndOfFrame();
        }
        
        transform.localScale = Vector3.one;
        rb.isKinematic = false;
        _isResetting = false;
        trailController.TurnOnTrail();
        yield break;

    }
}
