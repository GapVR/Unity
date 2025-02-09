#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;

public class RenderMaterialToTexture : EditorWindow
{
	private Material material;
	private int imagesize = 512;
	private string outfile = "Assets/RenderMaterialToTexture.png";
	private Texture2D previewImage;

	[MenuItem("Tools/Render Material To Image")]
	private static void ShowWindow()
	{
		GetWindow<RenderMaterialToTexture>("Render Material to Texture");
	}

	private void OnGUI()
	{
		material = (Material)EditorGUILayout.ObjectField("Material", material, typeof(Material), false);
		imagesize = EditorGUILayout.IntField("Image Size", imagesize);
		outfile = EditorGUILayout.TextField("Filepath", outfile);
		if (GUILayout.Button("Render"))
		{
			if (material != null)
			{
				renderImage();
				previewImage = AssetDatabase.LoadAssetAtPath<Texture2D>(outfile);
			}
		}
				if (previewImage != null)
				{
					GUILayout.Box(previewImage, GUILayout.Width(position.width*0.98f), GUILayout.Height(position.width*0.98f));
				}
	}

	private void renderImage()
	{
		RenderTexture renderTexture = new RenderTexture(imagesize, imagesize, 24);
		RenderTexture.active = renderTexture;

		// camera
		GameObject cameraobj = new GameObject("RenderMaterialToTextureCamera");
		Camera tempCamera = cameraobj.AddComponent<Camera>();
		tempCamera.backgroundColor = Color.clear;
		tempCamera.clearFlags = CameraClearFlags.SolidColor;
		tempCamera.targetTexture = renderTexture;

		// quad
		GameObject quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
		quad.transform.position = new Vector3(0, 0, 10);
		quad.GetComponent<Renderer>().material = material;

		tempCamera.transform.position = new Vector3(0, 0, 0);
		tempCamera.transform.LookAt(quad.transform);
		tempCamera.orthographic = true;
		tempCamera.orthographicSize = 0.5f;

		tempCamera.Render();

		// texture
		Texture2D texture = new Texture2D(imagesize, imagesize, TextureFormat.RGBA32, false);
		texture.ReadPixels(new Rect(0, 0, imagesize, imagesize), 0, 0);
		texture.Apply();

		// cleanup
		RenderTexture.active = null;
		DestroyImmediate(cameraobj);
		DestroyImmediate(quad);

		byte[] output = texture.EncodeToPNG();
		System.IO.File.WriteAllBytes(outfile, output);
		AssetDatabase.Refresh();

		Debug.Log("Render Material To Texture: " + material + " -> " + outfile);
	}
}

#endif