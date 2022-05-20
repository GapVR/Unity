/*
Modified from
	https://github.com/CascadianWorks/VRC-Auto-Toggle-Creator
Changes
	write defaults OFF
	ON and OFF replaced with 1 and 0 respectively
	changed naming to tog_<object>[_1|_0]
	creates two animation files for each state
	FX layer states to point to one another, entry leads to default state
	doesn't make a menu entry?
*/

using System.IO;
using UnityEditor;
using UnityEngine;
using System;
//using UnityEditorInternal;
 # if UNITY_EDITOR
using static VRC.SDKBase.VRC_AvatarParameterDriver;
using VRC.SDK3.Avatars.Components;
using VRC.SDK3.Avatars.ScriptableObjects;
using VRC.SDK3.Editor;
using UnityEditor.Animations;
public class AutoToggleCreator: EditorWindow
{
	public GameObject[]toggleObjects;
	public Animator myAnimator;
	int ogparamlength;
	AnimatorController controller;
	VRCExpressionParameters vrcParam;
	VRCExpressionsMenu vrcMenu;
	static bool parameterSave;
	static bool defaultOn;

	[MenuItem("Tools/AutoToggleCreator")]

	static void Init()
	{
		// Get existing open window or if none, make a new one:
		AutoToggleCreator window = (AutoToggleCreator)EditorWindow.GetWindow(typeof(AutoToggleCreator));
		window.Show();

	}

	public void OnGUI()
	{
		EditorGUILayout.Space(15);

		if (GUILayout.Button("Auto-Fill with Selected Avatar", GUILayout.Height(30f)))
		{
			Transform SelectedObj = Selection.activeTransform;
			myAnimator = SelectedObj.GetComponent < Animator > ();
			controller = (AnimatorController)SelectedObj.GetComponent < VRCAvatarDescriptor > ().baseAnimationLayers[4].animatorController;
			vrcParam = SelectedObj.GetComponent < VRCAvatarDescriptor > ().expressionParameters;
			vrcMenu = SelectedObj.GetComponent < VRCAvatarDescriptor > ().expressionsMenu;
		}

		EditorGUILayout.Space(10);

		EditorGUILayout.BeginHorizontal();
		EditorGUILayout.BeginVertical();
		//Avatar Animator
		GUILayout.Label("AVATAR ANIMATOR", EditorStyles.boldLabel);
		myAnimator = (Animator)EditorGUILayout.ObjectField(myAnimator, typeof(Animator), true, GUILayout.Height(40f));
		EditorGUILayout.EndVertical();

		EditorGUILayout.BeginVertical();
		//FX Animator Controller
		GUILayout.Label("FX AVATAR CONTROLLER", EditorStyles.boldLabel);
		controller = (AnimatorController)EditorGUILayout.ObjectField(controller, typeof(AnimatorController), true, GUILayout.Height(40f));
		EditorGUILayout.EndVertical();
		EditorGUILayout.EndHorizontal();

		EditorGUILayout.Space(15);

		EditorGUILayout.BeginHorizontal();
		EditorGUILayout.BeginVertical();
		//VRCExpressionParameters
		GUILayout.Label("VRC EXPRESSION PARAMETERS", EditorStyles.boldLabel);
		vrcParam = (VRCExpressionParameters)EditorGUILayout.ObjectField(vrcParam, typeof(VRCExpressionParameters), true, GUILayout.Height(40f));
		EditorGUILayout.EndVertical();

		EditorGUILayout.BeginVertical();
		//VRCExpressionMenu
		GUILayout.Label("VRC EXPRESSION MENU", EditorStyles.boldLabel);
		vrcMenu = (VRCExpressionsMenu)EditorGUILayout.ObjectField(vrcMenu, typeof(VRCExpressionsMenu), true, GUILayout.Height(40f));
		EditorGUILayout.EndVertical();
		EditorGUILayout.EndHorizontal();

		EditorGUILayout.Space(15);

		EditorGUI.BeginDisabledGroup((myAnimator && controller && vrcParam && vrcMenu) != true);

		EditorGUILayout.BeginHorizontal();
		//Toggle to save VRCParameter values
		parameterSave = (bool)EditorGUILayout.ToggleLeft("Save VRC Parameters?", parameterSave, EditorStyles.boldLabel);

		defaultOn = (bool)EditorGUILayout.ToggleLeft("Start On by Default?", defaultOn, EditorStyles.boldLabel);
		EditorGUILayout.EndHorizontal();

		GUILayout.Space(10f);

		//Toggle Object List
		GUILayout.Label("Objects to Toggle On and Off:", EditorStyles.boldLabel);
		ScriptableObject target = this;
		SerializedObject so = new SerializedObject(target);
		SerializedProperty toggleObjectsProperty = so.FindProperty("toggleObjects");
		EditorGUILayout.PropertyField(toggleObjectsProperty, true);
		GUILayout.Space(10f);

		if (GUILayout.Button("Create Toggles!", GUILayout.Height(40f)))
		{
			Preprocessing();
			CreateClips(); //Creates the Animation Clips needed for toggles.
			ApplyToAnimator(); //Handles making toggle bool property, layer setup, states and transitions.
			MakeVRCParameter(); //Makes a new VRCParameter list, populates it with existing parameters, then adds new ones for each toggle.
			MakeVRCMenu();
		}

		EditorGUI.EndDisabledGroup();

		so.ApplyModifiedProperties();
	}

	private void Preprocessing()
	{}

	private void CreateClips()
	{
		for (int i = 0; i < toggleObjects.Length; i++)
		{
			//Make animation clips for on and off state and set curves for game objects on and off
			AnimationClip toggleClipOn = new AnimationClip(); //Clip for ON

			toggleClipOn.legacy = false;
			toggleClipOn.SetCurve
			(GetGameObjectPath(toggleObjects[i].transform).Substring(myAnimator.gameObject.name.Length + 1),
				typeof(GameObject),
				"m_IsActive",
				new AnimationCurve(new Keyframe(0, 1f, 0, 0)));

			AnimationClip toggleClipOff = new AnimationClip(); //Clip for ON
			toggleClipOff.legacy = false;
			toggleClipOff.SetCurve
			(GetGameObjectPath(toggleObjects[i].transform).Substring(myAnimator.gameObject.name.Length + 1),
				typeof(GameObject),
				"m_IsActive",
				new AnimationCurve(new Keyframe(0, 0f, 0, 0)));

			//Check to see if path exists. If not, create it.
			if (!Directory.Exists($"Assets/ToggleAnimations/{myAnimator.gameObject.name}/"))
			{
				Directory.CreateDirectory($"Assets/ToggleAnimations/{myAnimator.gameObject.name}/");
			}

			AssetDatabase.CreateAsset(toggleClipOn, $"Assets/ToggleAnimations/{myAnimator.gameObject.name}/tog_{toggleObjects[i].name}_1.anim");
			AssetDatabase.CreateAsset(toggleClipOff, $"Assets/ToggleAnimations/{myAnimator.gameObject.name}/tog_{toggleObjects[i].name}_0.anim");
			AssetDatabase.SaveAssets();

		}
	}

	private void ApplyToAnimator()
	{
		for (int i = 0; i < toggleObjects.Length; i++)
		{
			bool existParam = doesNameExistParam("tog_" + toggleObjects[i].name, controller.parameters);
			bool existLayer = doesNameExistLayer(toggleObjects[i].name, controller.layers);

			//Check if a parameter already Ixists with that name. If so, Ignore adding parameter.
			if (existParam == false)
			{
				controller.AddParameter("tog_" + toggleObjects[i].name, UnityEngine.AnimatorControllerParameterType.Bool);
			}

			//Check if a layer already Ixists with that name. If so, Ignore adding layer.
			if (existLayer == false)
			{
				controller.AddLayer("tog_" + toggleObjects[i].name.Replace(".", "_"));

				AnimatorState stateOn;
				AnimatorState stateOff;

				//Adding created states to controller layer
				if (defaultOn == true)
				{

// UNITY IS FUCKING BUGGY: AddState: A newly declared and pre-fleshed out AnimatorState cannot be used as first param or the controller won't be saved. Works fine when it's a string.

					controller.layers[controller.layers.Length - 1].stateMachine.AddState("stateOn", new Vector3(270, 120, 0));
					stateOn = controller.layers[controller.layers.Length - 1].stateMachine.states[0].state;
					controller.layers[controller.layers.Length - 1].stateMachine.AddState("stateOff", new Vector3(270, 210, 0));
					stateOff = controller.layers[controller.layers.Length - 1].stateMachine.states[1].state;
				} else {
					controller.layers[controller.layers.Length - 1].stateMachine.AddState("stateOff", new Vector3(270, 120, 0));
					stateOff = controller.layers[controller.layers.Length - 1].stateMachine.states[0].state;
					controller.layers[controller.layers.Length - 1].stateMachine.AddState("stateOn", new Vector3(270, 30, 0));
					stateOn = controller.layers[controller.layers.Length - 1].stateMachine.states[1].state;
				}

				stateOn.name = "1";
				stateOn.writeDefaultValues = false;
				stateOn.motion = (Motion)AssetDatabase.LoadAssetAtPath($"Assets/ToggleAnimations/{myAnimator.gameObject.name}/tog_{toggleObjects[i].name}_1.anim", typeof(Motion));
				stateOff.name = "0";
				stateOff.writeDefaultValues = false;
				stateOff.motion = (Motion)AssetDatabase.LoadAssetAtPath($"Assets/ToggleAnimations/{myAnimator.gameObject.name}/tog_{toggleObjects[i].name}_0.anim", typeof(Motion));

				//Transition states
				AnimatorStateTransition OnOff = new AnimatorStateTransition();
				AnimatorStateTransition OffOn = new AnimatorStateTransition();
				if (defaultOn == true)
				{
					OffOn.AddCondition(AnimatorConditionMode.IfNot, 0, "tog_" + toggleObjects[i].name);
					OffOn.destinationState = controller.layers[controller.layers.Length - 1].stateMachine.states[0].state;

					OnOff.AddCondition(AnimatorConditionMode.If, 0, "tog_" + toggleObjects[i].name);
					OnOff.destinationState = controller.layers[controller.layers.Length - 1].stateMachine.states[1].state;
				} else {
					OffOn.AddCondition(AnimatorConditionMode.IfNot, 0, "tog_" + toggleObjects[i].name);
					OffOn.destinationState = controller.layers[controller.layers.Length - 1].stateMachine.states[1].state;

					OnOff.AddCondition(AnimatorConditionMode.If, 0, "tog_" + toggleObjects[i].name);
					OnOff.destinationState = controller.layers[controller.layers.Length - 1].stateMachine.states[0].state;
				}

				stateOff.AddTransition(OffOn.destinationState);
				stateOn.AddTransition(OnOff.destinationState);
				stateOff.transitions[0].duration = 0.0f;
				stateOn.transitions[0].duration = 0.0f;
				if (defaultOn == true)
				{
					stateOff.transitions[0].AddCondition(AnimatorConditionMode.IfNot, 0, "tog_" + toggleObjects[i].name);
					stateOn.transitions[0].AddCondition(AnimatorConditionMode.If, 0, "tog_" + toggleObjects[i].name);
				} else {
					stateOff.transitions[0].AddCondition(AnimatorConditionMode.If, 0, "tog_" + toggleObjects[i].name);
					stateOn.transitions[0].AddCondition(AnimatorConditionMode.IfNot, 0, "tog_" + toggleObjects[i].name);
				}

			}

			//Set Layer Weight
			UnityEditor.Animations.AnimatorControllerLayer[]layers = controller.layers;
			layers[controller.layers.Length - 1].defaultWeight = 1;
			controller.layers = layers;

			var dstControllerPath = AssetDatabase.GetAssetPath(controller);
			EditorUtility.SetDirty(controller);
			AssetDatabase.SaveAssets();
			AssetDatabase.Refresh();
		}
	}

	private void MakeVRCParameter()
	{
		VRCExpressionParameters.Parameter[]newList = new VRCExpressionParameters.Parameter[vrcParam.parameters.Length + toggleObjects.Length];

		ogparamlength = vrcParam.parameters.Length;

		//Add parameters that were already on the SO
		for (int i = 0; i < vrcParam.parameters.Length; i++)
		{
			newList[i] = vrcParam.parameters[i];
		}
		bool same = false;
		for (int i = 0; i < toggleObjects.Length; i++)
		{
			//Make new parameter to add to list
			VRCExpressionParameters.Parameter newParam = new VRCExpressionParameters.Parameter();

			int vrcParapLength = vrcParam.parameters.Length;

			//Modify parameter according to user settings and object name
			newParam.name = "tog_" + toggleObjects[i].name;
			newParam.valueType = VRCExpressionParameters.ValueType.Bool;
			newParam.defaultValue = 0;

			//Check to see if parameter is saved
			if (parameterSave == true)
			{
				newParam.saved = true;
			}
			else
			{
				newParam.saved = false;
			}

			same = false;

			//THis garbage here checks to see if there is already a parameter with the same name. If so, It ignore it and removes one slip from the predetermined list.
			for (int j = 0; j < vrcParapLength; j++)
			{
				if (newList[j].name == "tog_" + toggleObjects[i].name)
				{
					same = true;
					newList = new VRCExpressionParameters.Parameter[vrcParam.parameters.Length + toggleObjects.Length - 1 - i];

					for (int k = 0; k < vrcParam.parameters.Length; k++)
					{
						newList[k] = vrcParam.parameters[k];
					}
				}
			}

			//If no name name was found, then add parameter to list
			if (same == false)
			{
				newList[i + vrcParam.parameters.Length] = newParam;
			}
		}
		//Apply new list to VRCExpressionParameter asset
		vrcParam.parameters = newList;

		EditorUtility.SetDirty(vrcParam);
		AssetDatabase.SaveAssets();
		AssetDatabase.Refresh();
	}

	private void MakeVRCMenu()
	{
		bool menutoggle = false;
		for (int i = 0; i < toggleObjects.Length; i++)
		{
			VRCExpressionsMenu.Control controlItem = new VRCExpressionsMenu.Control();

			controlItem.name = toggleObjects[i].name;
			controlItem.type = VRCExpressionsMenu.Control.ControlType.Toggle;
			controlItem.parameter = new VRCExpressionsMenu.Control.Parameter();
			controlItem.parameter.name = "tog_" + toggleObjects[i].name;
			menutoggle = false;
			for (int j = 0; j < vrcMenu.controls.Count; j++)
			{
				if (vrcMenu.controls[j].name == controlItem.parameter.name)
				{
					menutoggle = true;
				}
			}

			if (menutoggle == false)
			{
				vrcMenu.controls.Add(controlItem);
			}
		}
		EditorUtility.SetDirty(vrcMenu);
		AssetDatabase.SaveAssets();
		AssetDatabase.Refresh();
	}

	private bool doesNameExistParam(string name, AnimatorControllerParameter[]array)
	{
		for (int i = 0; i < array.Length; i++)
		{
			if (array[i].name == name)
			{
				return true;
			}
		}
		return false;
	}

	private bool doesNameExistLayer(string name, AnimatorControllerLayer[]array)
	{
		for (int i = 0; i < array.Length; i++)
		{
			if (array[i].name == name)
			{
				return true;
			}
		}
		return false;
	}

	private string GetGameObjectPath(Transform transform)
	{
		string path = transform.name;
		while (transform.parent != null)
		{
			transform = transform.parent;
			path = transform.name + "/" + path;
		}
		return path;
	}

}
# endif
