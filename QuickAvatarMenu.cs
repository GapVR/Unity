// Hold Alt and press Q, then press 1-5 (for controllers), W for menu, E for Params, Q to select avatar
#if UNITY_EDITOR && VRC_SDK_VRCSDK3 && !UDON
using System;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using System.Reflection;
using VRC.SDK3.Avatars.Components;

namespace Nigger
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
			}
		}

		[MenuItem("Q Quick/1 Controller: FX")]
		private static void OA4()
		{
			OpenAsset(4);
		}

		[MenuItem("Q Quick/2 Controller: Gesture")]
		private static void OA2()
		{
			OpenAsset(2);
		}

		[MenuItem("Q Quick/3 Controller: Base")]
		private static void OA0()
		{
			OpenAsset(0);
		}

		[MenuItem("Q Quick/4 Controller: Additive")]
		private static void OA1()
		{
			OpenAsset(1);
		}

		[MenuItem("Q Quick/5 Controller: Action")]
		private static void OA3()
		{
			OpenAsset(3);
		}

		[MenuItem("Q Quick/W Expressions: Menu")]
		private static void OA11()
		{
			OpenAsset(11);
		}

		[MenuItem("Q Quick/E Expressions: Params")]
		private static void OA12()
		{
			OpenAsset(12);
		}

		[MenuItem("Q Quick/Q Select Avatar")]
		private static void OA100()
		{
			OpenAsset(100);
		}
	}
}
#endif
