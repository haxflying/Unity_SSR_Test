using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class ImageEffects : MonoBehaviour {

    public Material std;

    public Shader ssrShader;
    [Range(0, 0.1f)]
    public float epsion = 0.05f;
    [Range(1, 60)]
    public int it_count = 10;
    [Range(1, 40)]
    public int bs_it_count = 5;
    [Range(0, 1f)]
    public float stepSize;
    [Range(1f, 50f)]
    public float maxLength = 10;

    private Material mat;

    private Camera cam;

    private void Start()
    {
        mat = new Material(ssrShader);
        cam = Camera.main;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if(mat == null)
        {
            Graphics.Blit(src, dst);
        }
        else
        {
            mat.SetInt("MAX_IT_COUNT", it_count);
            mat.SetInt("MAX_BS_IT", bs_it_count); 
            mat.SetFloat("_MaxLength", maxLength);
            mat.SetFloat("EPSION", epsion);
            mat.SetFloat("_StepSize", stepSize);
            mat.SetMatrix("_NormalMatrix", Camera.current.worldToCameraMatrix);
            Graphics.Blit(src, dst, mat, 0);
        }
    }

    void RaycastCornerBlit(RenderTexture source, RenderTexture dest, Material mat)
    {
        // Compute Frustum Corners
        float camFar = cam.farClipPlane;
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = cam.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = cam.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (cam.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (cam.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (cam.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (cam.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

        // Custom Blit, encoding Frustum Corners as additional Texture Coordinates
        RenderTexture.active = dest;

        mat.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        mat.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
}
