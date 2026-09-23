// Headless UPM install/remove via the Package Manager Client API.
// Adapted from Unity-Technologies/skills (unity-package-management, MIT).
// Place under an Editor/ folder (e.g. Assets/Editor/ProjectBootstrap/).
// Run WITHOUT -quit: the request completes on later EditorApplication.update
// ticks and this script exits the Editor itself with a meaningful code.
//
//   Unity.exe -batchmode -projectPath <project>
//     -executeMethod ProjectBootstrap.PackageInstaller.Install -logFile -
//
// Exit codes: 0 resolved, 1 UPM error (message in the log), 2 timeout.
using System.Linq;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEngine;

namespace ProjectBootstrap
{
    public static class PackageInstaller
    {
        // Edit these. Pin with "@1.2.3" when a version matters.
        static readonly string[] PackagesToAdd = { "com.unity.inputsystem" };
        static readonly string[] PackagesToRemove = { };

        const double TimeoutSeconds = 600;

        static AddAndRemoveRequest request;
        static double deadline;

        public static void Install()
        {
            if (PackagesToAdd.Length == 0 && PackagesToRemove.Length == 0)
            {
                Debug.Log("[PackageInstaller] Nothing to do.");
                EditorApplication.Exit(0);
                return;
            }

            Debug.Log($"[PackageInstaller] Adding: {string.Join(", ", PackagesToAdd)}; removing: {string.Join(", ", PackagesToRemove)}");
            request = Client.AddAndRemove(packagesToAdd: PackagesToAdd, packagesToRemove: PackagesToRemove);
            deadline = EditorApplication.timeSinceStartup + TimeoutSeconds;
            EditorApplication.update += Poll;
        }

        static void Poll()
        {
            if (request == null) return;

            if (!request.IsCompleted)
            {
                if (EditorApplication.timeSinceStartup > deadline)
                {
                    EditorApplication.update -= Poll;
                    Debug.LogError("[PackageInstaller] Timed out waiting for UPM.");
                    EditorApplication.Exit(2);
                }
                return;
            }

            EditorApplication.update -= Poll;

            if (request.Status == StatusCode.Success)
            {
                var names = request.Result.Select(p => $"{p.name}@{p.version}");
                Debug.Log($"[PackageInstaller] Resolved: {string.Join(", ", names)}");
                EditorApplication.Exit(0);
            }
            else
            {
                Debug.LogError($"[PackageInstaller] Failed: {request.Error?.message}");
                EditorApplication.Exit(1);
            }
        }
    }

    // Lists registry packages and their latest compatible versions; same
    // poll-and-exit pattern. -executeMethod ProjectBootstrap.PackageSearch.SearchAll
    public static class PackageSearch
    {
        const double TimeoutSeconds = 120;
        static SearchRequest request;
        static double deadline;

        public static void SearchAll()
        {
            request = Client.SearchAll(); // or Client.Search("com.unity.cinemachine")
            deadline = EditorApplication.timeSinceStartup + TimeoutSeconds;
            EditorApplication.update += Poll;
        }

        static void Poll()
        {
            if (request == null) return;
            if (!request.IsCompleted)
            {
                if (EditorApplication.timeSinceStartup > deadline)
                {
                    EditorApplication.update -= Poll;
                    Debug.LogError("[PackageSearch] Timed out.");
                    EditorApplication.Exit(2);
                }
                return;
            }
            EditorApplication.update -= Poll;

            if (request.Status == StatusCode.Success)
            {
                foreach (var p in request.Result.OrderBy(p => p.name))
                    Debug.Log($"[PackageSearch] {p.name}@{p.versions.latestCompatible}  {p.displayName}");
                Debug.Log($"[PackageSearch] {request.Result.Length} packages found.");
                EditorApplication.Exit(0);
            }
            else
            {
                Debug.LogError($"[PackageSearch] Failed: {request.Error?.message}");
                EditorApplication.Exit(1);
            }
        }
    }
}
