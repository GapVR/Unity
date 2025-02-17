// Unity Editor Material List Tool
// v0.3 220520 https://github.com/GapVR
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
	GameObject lastobj;
	Vector2 scrollpos;
	bool lockObject;

	List<Material> allMats;
	List<SkinnedMeshRenderer> rendererSkinned;
	List<MeshRenderer> rendererMesh;
	List<Tuple<AnimationClip, Material>> LclipMats;
	int LClipCount;

	void OnInspectorUpdate()
	{
		Repaint();
	}

	public MaterialList()
	{
		allMats = new List<Material>();
		rendererSkinned = new List<SkinnedMeshRenderer>();
		rendererMesh = new List<MeshRenderer>();
		LclipMats = new List<Tuple<AnimationClip, Material>>();
	}

	private void OnGUI()
	{
		bool includeInactive = true;

		obj = (GameObject)EditorGUILayout.ObjectField("GameObject", obj, typeof(GameObject), true);
		lockObject = EditorGUILayout.ToggleLeft("Lock", lockObject);
		if (!lockObject)
			obj = Selection.activeObject as GameObject;

		if (obj != null)
		{
			if (lastobj != obj)
			{
				allMats.Clear();
				LclipMats.Clear();
				LClipCount = 0;
			}

			EditorGUILayout.Space();

			scrollpos = EditorGUILayout.BeginScrollView(scrollpos);

			if (lastobj != obj) rendererSkinned = obj.GetComponentsInChildren<SkinnedMeshRenderer>(includeInactive).ToList();
			GUILayout.Label("Skinned Mesh Renderers (" + rendererSkinned.Count().ToString() + ")", EditorStyles.boldLabel);
			foreach (SkinnedMeshRenderer r in rendererSkinned)
			{
				EditorGUILayout.ObjectField(r, typeof(SkinnedMeshRenderer), false);
				EditorGUI.indentLevel += 2;
				foreach (Material m in r.sharedMaterials.Distinct().ToList())
				{
					EditorGUILayout.ObjectField(m, typeof(Material), false);
					if (lastobj != obj) allMats.Add(m);
				}
				EditorGUI.indentLevel -= 2;
			}

			EditorGUILayout.Space();

			if (lastobj != obj) rendererMesh = obj.GetComponentsInChildren<MeshRenderer>(includeInactive).ToList();
			GUILayout.Label("Mesh Renderers (" + rendererMesh.Count().ToString() + ")", EditorStyles.boldLabel);
			foreach (MeshRenderer r in rendererMesh)
			{
				EditorGUILayout.ObjectField(r, typeof(MeshRenderer), false);
				EditorGUI.indentLevel += 2;
				foreach (Material m in r.sharedMaterials.Distinct().ToList())
				{
					EditorGUILayout.ObjectField(m, typeof(Material), false);
					if (lastobj != obj) allMats.Add(m);
				}
				EditorGUI.indentLevel -= 2;
			}

#if VRC_SDK_VRCSDK3 && !UDON
				if (lastobj != obj)
				{
					VRCAvatarDescriptor descriptor = obj.GetComponent<VRCAvatarDescriptor>();
					if (descriptor != null)
					{
						IEnumerable<AnimationClip> clips = descriptor.baseAnimationLayers.Select(l => l.animatorController).Where(a => a != null).SelectMany(a => a.animationClips).Distinct();
						foreach (AnimationClip clip in clips)
						{
							IEnumerable<Material> clipMaterials = AnimationUtility.GetObjectReferenceCurveBindings(clip).Where(b => b.isPPtrCurve && b.type.IsSubclassOf(typeof(Renderer)) && b.propertyName.StartsWith("m_Materials")).SelectMany(b => AnimationUtility.GetObjectReferenceCurve(clip, b)).Select(r => r.value as Material);
							if (clipMaterials.Count() < 1) continue;
							allMats.AddRange(clipMaterials);
							foreach (Material m in clipMaterials)
							{
								LclipMats.Add(Tuple.Create(clip,m));
								LClipCount++;
							}
						}
					}
				}

				if (LclipMats.Count() > 0)
				{
					EditorGUILayout.Space();
					GUILayout.Label("Animation ("+LClipCount+")", EditorStyles.boldLabel);
					object prev = null;
					foreach (Tuple<AnimationClip, Material> tup in LclipMats)
					{
						if (!object.ReferenceEquals(tup.Item1, prev)) // tup.Item1 != prev
						{
							EditorGUILayout.ObjectField(tup.Item1, typeof(AnimationClip), false);
						}
						EditorGUI.indentLevel += 2;
						EditorGUILayout.ObjectField(tup.Item2, typeof(Material), false);
						EditorGUI.indentLevel -= 2;
						prev = tup.Item1;
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

			lastobj = obj;
		}
	}
}
#endif
