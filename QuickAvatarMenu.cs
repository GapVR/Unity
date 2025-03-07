// Quick Avatar Menu Tool
// v0.2 250209 Added: Print World Position
// v0.1 240109 Initial version.
// https://github.com/GapVR
// Press Alt+Q, then press the menu item key
#if UNITY_EDITOR && VRC_SDK_VRCSDK3 && !UDON
using System;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using System.Reflection;
using VRC.SDK3.Avatars.Components;

namespace takowasabi
{
	public class QuickAvatarMenu : EditorWindow
	{
		private static void OpenAsset(int num)
		{
			VRCAvatarDescriptor[] avvieDesc = GameObject.FindObjectsOfType<VRCAvatarDescriptor>();
			if (avvieDesc.Length > 0)
			{
				if (num < 10)
					AssetDatabase.OpenAsset((AnimatorController)avvieDesc[0].baseAnimationLayers[num].animatorController);
				else if (num == 11)
					AssetDatabase.OpenAsset(avvieDesc[0].expressionsMenu);
				else if (num == 12)
					AssetDatabase.OpenAsset(avvieDesc[0].expressionParameters);
				else if (num == 100)
					Selection.activeGameObject = avvieDesc[0].gameObject;
				else if (num == 200)
					Selection.activeGameObject = GameObject.Find(avvieDesc[0].gameObject.name + "/Armature/Hips/Spine/Chest/Neck/Head");
			}
		}

		[MenuItem("Q Quick/1	Layers: FX")]
		private static void OA4() { OpenAsset(4); }

		[MenuItem("Q Quick/2	Layers: Gesture")]
		private static void OA2() { OpenAsset(2); }

		[MenuItem("Q Quick/3	Layers: Base")]
		private static void OA0() { OpenAsset(0); }

		[MenuItem("Q Quick/4	Layers: Additive")]
		private static void OA1() { OpenAsset(1); }

		[MenuItem("Q Quick/5	Layers: Action")]
		private static void OA3() { OpenAsset(3); }

		[MenuItem("Q Quick/W	Expressions: Menu")]
		private static void OA11() { OpenAsset(11); }

		[MenuItem("Q Quick/E	Expressions: Parameters")]
		private static void OA12() { OpenAsset(12); }

		[MenuItem("Q Quick/A	Select: Armature (Head)")]
		private static void OA200() { OpenAsset(200); }

		[MenuItem("Q Quick/Q	Select: Avatar")]
		private static void OA100() { OpenAsset(100); }

		[MenuItem("Q Quick/P	Print: World Position")]
		private static void WorldPos()
		{
			string buf = "";
			foreach (GameObject obj in Selection.gameObjects)
				buf += obj.name + " " + obj.transform.position + "\n";
			if (buf != "")
				EditorUtility.DisplayDialog("WorldPos", buf, "OK");
		}
	}
}
#endif
