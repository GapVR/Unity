#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;

public class MemoComponent : MonoBehaviour
{
	[TextArea()]
	public string Memo = "";
}

[CustomEditor(typeof(MemoComponent))]
public class MemoComponentEditor : Editor
{
	public override void OnInspectorGUI()
	{
		MemoComponent MemoComponent = (MemoComponent)target;
		MemoComponent.Memo = EditorGUILayout.TextArea(MemoComponent.Memo);
		if (GUI.changed)
		{
			EditorUtility.SetDirty(MemoComponent);
		}
	}
}

#endif