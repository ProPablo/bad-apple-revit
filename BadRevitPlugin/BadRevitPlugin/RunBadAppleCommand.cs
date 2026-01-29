using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]

    public class RunBadAppleCommand : IExternalCommand
    {
        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            //if (BadApple.Instance == null)
            {
                BadApple.Instance = new BadAppleInstance();
                BadApple.Application = commandData.Application;
                var res = BadApple.Instance.InitResources(commandData.Application.ActiveUIDocument.Document);
                //if (res != Result.Succeeded)
                //{
                //    BadApple.Instance = null;
                //    return res;
                //}

                return BadApple.Instance.DrawFirstFrame();
            }
            //else
            //{
            //    return BadApple.Instance.DrawFirstFrame();
            //}
            // TODO cancel the operation here
            return Result.Cancelled;
        }
    }
}
