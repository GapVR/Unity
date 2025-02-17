// BlendshapeNamedCopyPaste
// https://github.com/GapVR
// v0.2 250217 - no index copy
// v0.1 250122 - initial version

#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using System.Text;

public class BlendshapeNamedCopyPaste : Editor
{
	private static void ImportClipboard (int importMode)
	{
		GameObject selectedObject = Selection.activeGameObject;
		if (selectedObject == null)
			return;

		SkinnedMeshRenderer skinnedMeshRenderer = selectedObject.GetComponent<SkinnedMeshRenderer>();
		if (skinnedMeshRenderer == null)
			return;

		string clipboardText = EditorGUIUtility.systemCopyBuffer;
		string[] lines = clipboardText.Split(new[]{'\n',';'}, System.StringSplitOptions.RemoveEmptyEntries);

		foreach (string line in lines)
		{
			string[] parts = line.Split(',');
			if (parts.Length > 1)
			{
				string blendShapeName = parts[0].Trim();
				if (float.TryParse(parts[1].Trim(), out float weight))
				{
					// source: non-zero
					if ((importMode == 1) && weight <= 0)
					{
						continue;
					}

					int index = skinnedMeshRenderer.sharedMesh.GetBlendShapeIndex(blendShapeName);
					if (index != -1)
					{
						// target: zero
						if (importMode == 2)
						{
							if (skinnedMeshRenderer.GetBlendShapeWeight(index) > 0)
							{
								continue;
							}
						}
						skinnedMeshRenderer.SetBlendShapeWeight(index, weight);
					}
					else
					{
						Debug.LogWarning($"BlendshapeNamedCopyPaste: BlendShape '{blendShapeName}' not found.");
					}
				}
			}
		}
		Debug.Log("BlendshapeNamedCopyPaste: Paste done.");
	}

	public static void ExportClipboard (int exportMode)
	{
		GameObject obj = Selection.activeGameObject;
		if (obj == null)
			return;

		SkinnedMeshRenderer smk = obj.GetComponent<SkinnedMeshRenderer>();
		if (smk == null)
			return;

		string strbuf;
		if (exportMode == 1)
			strbuf = "<name>,<weight>,<index>\n";
		else
			strbuf = "<name>,<weight>\n";
		for (int i = 0; i < smk.sharedMesh.blendShapeCount; i++)
		{
			string name = smk.sharedMesh.GetBlendShapeName(i);
			float weight = smk.GetBlendShapeWeight(i);
			if (exportMode == 1)
				strbuf += $"{name},{weight},{i}\n";
			else
				strbuf += $"{name},{weight}\n";
		}

		EditorGUIUtility.systemCopyBuffer = strbuf;
		Debug.Log("BlendshapeNamedCopyPaste: Copy done.");
	}

	[MenuItem("Tools/BlendshapeNamedCopyPaste/&Copy")]
	public static void ExportNormal()
	{
		ExportClipboard(0);
	}

	[MenuItem("Tools/BlendshapeNamedCopyPaste/Copy (with index)")]
	public static void ExportWithIndex()
	{
		ExportClipboard(1);
	}

	[MenuItem("Tools/BlendshapeNamedCopyPaste/Paste")]
	public static void ImportAll()
	{
		ImportClipboard(0);
	}

	[MenuItem("Tools/BlendshapeNamedCopyPaste/Paste (Source: Non-Zero)")]
	public static void ImportSourceNonZero()
	{
		ImportClipboard(1);
	}

	[MenuItem("Tools/BlendshapeNamedCopyPaste/Paste (Target: Zero only)")]
	public static void ImportTargetZero()
	{
		ImportClipboard(2);
	}
}

#endif
