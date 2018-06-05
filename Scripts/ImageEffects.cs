using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class ImageEffects : MonoBehaviour {

    [Header("SSR")]
    public Shader ssrShader;
    public Shader blurShader;
    public Shader combineShader;
    [Range(0, 0.1f)]
    public float epsion = 0.05f;
    [Range(0, 0.1f)]
    public float stepSize;
    [Range(1f, 50f)]
    public float maxLength = 10;
    [Header("Blur")]
    [Range(0, 4)]
    public int iterations = 3;
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    [Range(1, 8)]
    public int downSample = 2;

    private Material reflectMat, blurMat, combineMat;
    private Camera cam;

    private void Start()
    {
        reflectMat = new Material(ssrShader);
        blurMat = new Material(blurShader);
        combineMat = new Material(combineShader);
        cam = Camera.main;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (combineMat != null)
        {
            RenderTexture original_scene = RenderTexture.GetTemporary(src.width, src.height, 0);
            Graphics.Blit(src, original_scene);

            RenderTexture b4_blur_refl = RenderTexture.GetTemporary(src.width, src.height, 0, RenderTextureFormat.ARGB32);

            if (reflectMat == null)
            {
                Graphics.Blit(src, dst);
            }
            else
            {
                reflectMat.SetFloat("_MaxLength", maxLength);
                reflectMat.SetFloat("EPSION", epsion);
                reflectMat.SetFloat("_StepSize", stepSize);
                reflectMat.SetMatrix("_NormalMatrix", Camera.current.worldToCameraMatrix);               
                Graphics.Blit(src, b4_blur_refl, reflectMat, 0);
            }

            if (blurMat != null)
            {
                int rtW = b4_blur_refl.width / downSample;
                int rtH = b4_blur_refl.height / downSample;

                RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGB32);
                buffer0.filterMode = FilterMode.Bilinear;

                Graphics.Blit(b4_blur_refl, buffer0);

                for (int i = 0; i < iterations; i++)
                {
                    
                    blurMat.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                    RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, RenderTextureFormat.ARGB32);

                    Graphics.Blit(buffer0, buffer1, blurMat, 0);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                    buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                    Graphics.Blit(buffer0, buffer1, blurMat, 1);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                }
                RenderTexture after_blur_refl = RenderTexture.GetTemporary(buffer0.width, buffer0.height, 0, RenderTextureFormat.ARGB32);

                Graphics.Blit(buffer0, after_blur_refl);
                RenderTexture.ReleaseTemporary(buffer0);

                combineMat.SetTexture("_b4Blur", b4_blur_refl);
                combineMat.SetTexture("_gbuffer3", original_scene);
                Graphics.Blit(after_blur_refl, dst, combineMat);

                RenderTexture.ReleaseTemporary(original_scene);
                RenderTexture.ReleaseTemporary(b4_blur_refl);
                RenderTexture.ReleaseTemporary(after_blur_refl);
            }
        }
        else
        {
            Graphics.Blit(src, dst);
        }
    }
}
