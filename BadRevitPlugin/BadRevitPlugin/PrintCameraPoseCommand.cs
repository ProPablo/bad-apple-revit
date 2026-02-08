using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Text;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class PrintCameraPoseCommand : IExternalCommand
    {
        private CameraAnimator animator = new();


        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            UIDocument uidoc = commandData.Application.ActiveUIDocument;
            Document doc = uidoc.Document;
            View3D view3D = doc.ActiveView as View3D;

            if (view3D == null)
            {
                TaskDialog.Show("Error", "Please activate a 3D view first");
                return Result.Failed;
            }

            ViewOrientation3D orientation = view3D.GetOrientation();

            XYZ eyePosition = orientation.EyePosition;
            XYZ upDirection = orientation.UpDirection;
            XYZ forwardDirection = orientation.ForwardDirection;

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("=== CAMERA POSE ===");
            sb.AppendLine();
            sb.AppendLine($"Eye Position: ({eyePosition.X:F6}, {eyePosition.Y:F6}, {eyePosition.Z:F6})");
            sb.AppendLine($"Up Direction: ({upDirection.X:F6}, {upDirection.Y:F6}, {upDirection.Z:F6})");
            sb.AppendLine($"Forward Direction: ({forwardDirection.X:F6}, {forwardDirection.Y:F6}, {forwardDirection.Z:F6})");
            sb.AppendLine();
            sb.AppendLine("=== FOR CODE ===");
            sb.AppendLine($"XYZ eyePos = new XYZ({eyePosition.X}, {eyePosition.Y}, {eyePosition.Z});");
            sb.AppendLine($"XYZ upDir = new XYZ({upDirection.X}, {upDirection.Y}, {upDirection.Z});");
            sb.AppendLine($"XYZ forwardDir = new XYZ({forwardDirection.X}, {forwardDirection.Y}, {forwardDirection.Z});");

            // Also write to console for easy copying
            Console.WriteLine(sb.ToString());

            TaskDialog.Show("Camera Pose", sb.ToString());



            // Travel to start pos
            using (Transaction trans = new Transaction(doc, "Animate Camera"))
            {

                // Get the active 3D view
                var activeView3D = doc.ActiveView as View3D;
                if (activeView3D == null)
                {
                    TaskDialog.Show("Error", "Please activate a 3D view before starting");
                    return Result.Failed;
                }

                trans.Start();
                var endQuat = animator.ViewOrientationToQuaternion(animator.EndOrientation);
                var endOrient = animator.QuaternionToViewVectors(endQuat);
                var endOrientAll = new ViewOrientation3D(animator.EndOrientation.EyePosition, endOrient.up, endOrient.forward);

                //ViewOrientation3D newOrientation = animator.StartOrientation;

                activeView3D.SetOrientation(endOrientAll);
                //activeView3D.SetOrientation(animator.EndOrientation);


                //This has to be called for some reason to "rerender" the view.
                //This function does not work on the default view but 
                activeView3D.SaveOrientation();
                trans.Commit();
            }

            return Result.Succeeded;
        }
    }
}


