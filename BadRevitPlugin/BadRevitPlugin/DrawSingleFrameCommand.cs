using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class DrawSingleFrameCommand : IExternalCommand
    {
        private const int FRAME_INDEX = 15; // Change this to draw a different frame
        //private const int FRAME_INDEX = 2; 

        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            //Might be good case for self managed singleton
            if (BadApple.Resources == null)
            {
                BadApple.Application = commandData.Application;
                BadApple.Resources = new RevitResources();
                var res = BadApple.Resources.InitResources(commandData.Application.ActiveUIDocument.Document);

                if (res != Result.Succeeded)
                {
                    BadApple.Instance = null;
                    return res;
                }
            }

            BadApple.Instance = new BadAppleInstance();
            BadApple.Instance.isRunning = false;

            // Draw the frame
            return BadApple.Instance.DrawFrame(FRAME_INDEX);
        }
    }
}
