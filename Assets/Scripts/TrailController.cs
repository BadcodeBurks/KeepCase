using System;
using UnityEngine;

public class TrailController : MonoBehaviour
{
    public ParticleSystem ps;
    
    // private void OnTriggerEnter(Collider other)
    // {
    //     ps.Play();
    // }
    //
    // private void OnTriggerExit(Collider other)
    // {
    //     ps.Stop();
    // }

    public void TurnOffTrail()
    {
        ps.Stop();
    }
    
    public void TurnOnTrail()
    {
        ps.Play();
    }
}
