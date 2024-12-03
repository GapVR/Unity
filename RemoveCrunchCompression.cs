// Unity Editor Remove Crunch Compression Tool
// v0.1 241203 https://github.com/GapVR

using UnityEngine;
using UnityEditor;
using System.IO;

public class RemoveCrunchCompression : EditorWindow
{
	[MenuItem("Tools/Remove Crunch Compression [Textures]")]
	public static void Uncrunch()
	{
		string[] textureGUIDs = AssetDatabase.FindAssets("t:texture");
		int i = 0;

		foreach (string guid in textureGUIDs)
		{
			string tex = AssetDatabase.GUIDToAssetPath(guid);
			TextureImporter textureImporter = AssetImporter.GetAtPath(tex) as TextureImporter;

			if (textureImporter != null)
			{
				if (textureImporter.crunchedCompression)
				{
					textureImporter.crunchedCompression = false;
					textureImporter.SaveAndReimport();
					Debug.Log($"RemoveCrunchCompression: {tex}");
					i++;
				}
			}
		}
		Debug.Log($"RemoveCrunchCompression: Done. Processed {i} files.");
	}
}
