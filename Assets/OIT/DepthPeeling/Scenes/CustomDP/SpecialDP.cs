using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SpecialDP : MonoBehaviour
{

    public enum TransparentMode { ODT = 0, DepthPeeling }

    #region Public params
    public Shader initializationShader = null;
    public Shader depthPeelingShader = null;
    [Range(2, 8)]
    public int layers = 4;
    public int dispLayer = 0;
    #endregion

    #region Private params
    private Camera m_camera = null;
    private Camera m_transparentCamera = null;
    private GameObject m_transparentCameraObj = null;
    private RenderTexture m_opaqueTex = null;
    private RenderTexture[] m_depthTexs = null;
    #endregion

    // Use this for initialization
    void Awake()
    {
        m_camera = GetComponent<Camera>();
        if (m_transparentCameraObj != null)
        {
            DestroyImmediate(m_transparentCameraObj);
        }
        m_transparentCameraObj = new GameObject("OITCamera");
        m_transparentCameraObj.hideFlags = HideFlags.DontSave;
        m_transparentCameraObj.transform.parent = transform;
        m_transparentCameraObj.transform.localPosition = Vector3.zero;
        m_transparentCamera = m_transparentCameraObj.AddComponent<Camera>();
        m_transparentCamera.CopyFrom(m_camera);
        m_transparentCamera.clearFlags = CameraClearFlags.SolidColor;
        m_transparentCamera.cullingMask = 0xFFFFFF;
        m_transparentCamera.enabled = false;

        m_depthTexs = new RenderTexture[2];
    }

    void OnDestroy()
    {
        DestroyImmediate(m_transparentCameraObj);
    }

    void OnPreRender()
    {
        m_camera.cullingMask = 0;
    }

    void Update()
    {
        if (Input.GetKeyDown("space"))
            Write2File();
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (depthPeelingShader == null || initializationShader == null)
        {
            Graphics.Blit(src, dst);
            return;
        }

        m_opaqueTex = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        m_depthTexs[0] = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        m_depthTexs[1] = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        RenderTexture[] colorTexs = new RenderTexture[layers];
        colorTexs[0] = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

        // First iteration to render the scene as normal
        RenderBuffer[] mrtBuffers = new RenderBuffer[2];
        mrtBuffers[0] = colorTexs[0].colorBuffer;
        mrtBuffers[1] = m_depthTexs[0].colorBuffer;
        m_transparentCamera.SetTargetBuffers(mrtBuffers, m_opaqueTex.depthBuffer);
        m_transparentCamera.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.0f);
        m_transparentCamera.clearFlags = CameraClearFlags.Color;
        m_transparentCamera.RenderWithShader(initializationShader, null);

        // Then, peel away the depth
        for (int i = 1; i < layers; i++)
        {
            colorTexs[i] = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            mrtBuffers[0] = colorTexs[i].colorBuffer;
            mrtBuffers[1] = m_depthTexs[i % 2].colorBuffer;
            m_transparentCamera.SetTargetBuffers(mrtBuffers, m_opaqueTex.depthBuffer);
            m_transparentCamera.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.0f);
            Shader.SetGlobalTexture("_PrevDepthTex", m_depthTexs[1 - i % 2]);
            m_transparentCamera.RenderWithShader(depthPeelingShader, null);
        }

        Graphics.Blit(colorTexs[dispLayer], dst);

        RenderTexture.ReleaseTemporary(m_opaqueTex);
        RenderTexture.ReleaseTemporary(m_depthTexs[0]);
        RenderTexture.ReleaseTemporary(m_depthTexs[1]);
        for (int i = 0; i < layers; i++)
            RenderTexture.ReleaseTemporary(colorTexs[i]);
    }

    void Write2File()
    {
        var FName = "DPNOCS_" + dispLayer.ToString("000") + ".png";
        ScreenCapture.CaptureScreenshot(FName);
        Debug.Log("Wrote: " + FName);
    }
}
