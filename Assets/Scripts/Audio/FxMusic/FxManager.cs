﻿using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;

public class FxManager: MonoBehaviour
{
    public AudioSource musicSource;
    void Update()
    {
        musicSource.volume = PlayerPrefs.GetFloat("FxVolume")/6;
    }


}