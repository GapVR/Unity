// Unity Editor Material List Tool
// v0.2 220520 https://github.com/GapVR
// Reference: Thry's Avatar Evaluator, https://github.com/Thryrallo/VRCAvatarTools/

#if UNITY_EDITOR

using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
#if VRC_SDK_VRCSDK3 && !UDON
using VRC.SDK3.Avatars.Components;
#endif

public class MaterialList: EditorWindow
{
	[MenuItem("Tools/Material List")]
	public static void Init()
	{
		MaterialList window = (MaterialList)EditorWindow.GetWindow(typeof(MaterialList));
		window.titleContent = new GUIContent("Material List");
		window.Show();
	}

	GameObject obj;
	Vector2 scrollpos;
	bool lockObject;

	void OnInspectorUpdate()
	{
		Repaint();
	}

	private void OnGUI()
	{
		bool includeInactive = true;

		EditorGUI.BeginChangeCheck();
		obj = (GameObject)EditorGUILayout.ObjectField("GameObject", obj, typeof(GameObject), true);
		lockObject = EditorGUILayout.ToggleLeft("Lock", lockObject);
		if (!lockObject)
			obj = Selection.activeObject as GameObject;
		EditorGUI.EndChangeCheck();

		if (obj != null)
		{
			EditorGUILayout.Space();

			scrollpos = EditorGUILayout.BeginScrollView(scrollpos);

			List<Material> allMats = new List<Material>();

			List<SkinnedMeshRenderer> rendererSkinned = obj.GetComponentsInChildren<SkinnedMeshRenderer>(includeInactive).ToList();
			GUILayout.Label("Skinned Mesh Renderers (" + rendererSkinned.Count().ToString() + ")", EditorStyles.boldLabel);
			foreach (SkinnedMeshRenderer r in rendererSkinned)
			{
				EditorGUILayout.ObjectField(r, typeof(SkinnedMeshRenderer), false);
				EditorGUI.indentLevel += 2;
				foreach (Material m in r.sharedMaterials.Distinct().ToList())
				{
					EditorGUILayout.ObjectField(m, typeof(Material), false);
					allMats.Add(m);
				}
				EditorGUI.indentLevel -= 2;
			}

			EditorGUILayout.Space();

			List<MeshRenderer> rendererMesh = obj.GetComponentsInChildren<MeshRenderer>(includeInactive).ToList();
			GUILayout.Label("Mesh Renderers (" + rendererMesh.Count().ToString() + ")", EditorStyles.boldLabel);
			foreach (MeshRenderer r in rendererMesh)
			{
				EditorGUILayout.ObjectField(r, typeof(MeshRenderer), false);
				EditorGUI.indentLevel += 2;
				foreach (Material m in r.sharedMaterials.Distinct().ToList())
				{
					EditorGUILayout.ObjectField(m, typeof(Material), false);
					allMats.Add(m);
				}
				EditorGUI.indentLevel -= 2;
			}

#if VRC_SDK_VRCSDK3 && !UDON
			VRCAvatarDescriptor descriptor = obj.GetComponent<VRCAvatarDescriptor>();
			if (descriptor != null)
			{
				EditorGUILayout.Space();

				IEnumerable<AnimationClip> clips = descriptor.baseAnimationLayers.Select(l => l.animatorController).Where(a => a != null).SelectMany(a => a.animationClips).Distinct();
				GUILayout.Label("Animators (Animation)", EditorStyles.boldLabel);
				foreach (AnimationClip clip in clips)
				{
					IEnumerable<Material> clipMaterials = AnimationUtility.GetObjectReferenceCurveBindings(clip).Where(b => b.isPPtrCurve && b.type.IsSubclassOf(typeof(Renderer)) && b.propertyName.StartsWith("m_Materials")).SelectMany(b => AnimationUtility.GetObjectReferenceCurve(clip, b)).Select(r => r.value as Material);

					if (clipMaterials.Count() < 1) continue;

					EditorGUILayout.ObjectField(clip, typeof(AnimationClip), false);
					EditorGUI.indentLevel += 2;

					allMats.AddRange(clipMaterials);

					foreach (Material m in clipMaterials)
					{
						EditorGUILayout.ObjectField(m, typeof(Material), false);
					}
					EditorGUI.indentLevel -= 2;
				}
			}
#endif

			EditorGUILayout.Space();

			GUILayout.Label("All Slot Materials (" + allMats.Count().ToString() + ")", EditorStyles.boldLabel);
			foreach (Material m in allMats)
			{
				EditorGUILayout.ObjectField(m, typeof(Material), false);
			}

			EditorGUILayout.Space();

			EditorGUILayout.EndScrollView();
		}
	}
}
#endif
