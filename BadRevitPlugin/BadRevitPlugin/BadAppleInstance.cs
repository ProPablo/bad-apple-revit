using Autodesk.Revit.DB;
using Autodesk.Revit.DB.Architecture;
using Autodesk.Revit.UI;
using MatFileHandler;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public class BadAppleInstance
    {
        public MatLoader loader;
        public int frameNum = 0;

        public DateTime lastTimeRun;
        public static TimeSpan FRAME_TIME = TimeSpan.FromMilliseconds(20);
        public BadAppleInstance()
        {
            loader = new MatLoader();
            loader.Load();
        }

        public bool isInit = false;


        Document doc;
        double wallHeight;
        WallType wallType;
        Level level;

        double ceilingHeight;
        CeilingType ceilingType;

        public Result InitResources(Document doc)
        {
            this.doc = doc;

            //double wallHeight = 10.0; // 10 feet
            var instancedWall = GetWall();
            if (instancedWall == null)
            {
                TaskDialog.Show("Error", "Wall not found");
                return Result.Failed;
            }

            // Get its type, level, and height
            wallType = instancedWall.WallType;
            level = doc.GetElement(instancedWall.LevelId) as Level;
            wallHeight = instancedWall.get_Parameter(BuiltInParameter.WALL_USER_HEIGHT_PARAM).AsDouble();


            // Get ceiling type by name
            ceilingType = new FilteredElementCollector(doc)
                .OfClass(typeof(CeilingType))
                .Cast<CeilingType>()
                .FirstOrDefault(c => c.Name.Contains("Epic ceiling"));

            Ceiling ceiling = new FilteredElementCollector(doc)
                .OfClass(typeof(Ceiling))
                .Cast<Ceiling>()
                .FirstOrDefault(c => c.Name.Contains("Epic ceiling"));

            if (ceilingType == null || ceiling == null)
            {
                TaskDialog.Show("Error", "Ceiling type or ceiling not found");
                return Result.Failed;
            }

            Parameter param = ceiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            ceilingHeight = param.AsDouble();

            return Result.Succeeded;
        }

        public Result DrawSingleBoundary(RoomBoundary room, Document doc)
        {
            var ceilingCurveLoops = new List<CurveLoop>();

            // Create ceiling from your points
            List<Curve> outerLoop = new();
            // Create walls between consecutive points
            for (int i = 0; i < room.MainOuterLoop.Count; i++)
            {
                XYZ start = room.MainOuterLoop[i];
                XYZ end = room.MainOuterLoop[(i + 1) % room.MainOuterLoop.Count]; // Wrap around to close the loop

                Line wallLine = Line.CreateBound(start, end);

                Wall wall = Wall.Create(doc, wallLine, wallType.Id, level.Id, wallHeight, 0, false, false);

                outerLoop.Add(wallLine);
            }

            ceilingCurveLoops.Add(CurveLoop.Create(outerLoop));


            foreach (var loop in room.InnerLoops)
            {
                List<Curve> innerLoop = new();
                for (int i = 0; i < loop.Count; i++)
                {
                    XYZ start = loop[i];
                    XYZ end = loop[(i + 1) % loop.Count]; // Wrap around to close the loop

                    Line wallLine = Line.CreateBound(start, end);

                    Wall wall = Wall.Create(doc, wallLine, wallType.Id, level.Id, wallHeight, 0, false, false);

                    innerLoop.Add(wallLine);
                }
                ceilingCurveLoops.Add(CurveLoop.Create(innerLoop));
            }


            UV uvPoint = room.centroid;

            for (int i = 0; i < room.MainOuterLoop.Count; i++)
            {
                XYZ start = room.MainOuterLoop[i];
                XYZ end = room.MainOuterLoop[(i + 1) % room.MainOuterLoop.Count];
                outerLoop.Add(Line.CreateBound(start, end));
            }


            doc.Create.NewRoom(level, uvPoint);

            var newCeiling = Ceiling.Create(doc, ceilingCurveLoops, ceilingType.Id, level.Id);
            Parameter newCeilingParam = newCeiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            newCeilingParam.Set(ceilingHeight);


            return Result.Succeeded;

        }

        void TestCeiling()
        {
            // Your outer polygon points
            List<XYZ> outerPoints = new List<XYZ>
            {
                new XYZ(0, 0, 0),
                new XYZ(20, 0, 0),
                new XYZ(20, 20, 0),
                new XYZ(0, 20, 0)
            };

            // Your inner polygon points (hole/void)
            List<XYZ> innerPoints = new List<XYZ>
            {
                new XYZ(5, 5, 0),
                new XYZ(10, 5, 0),
                new XYZ(10, 10, 0),
                new XYZ(5, 10, 0)
            };

            // Create outer boundary
            List<Curve> outerCurves = new();
            for (int i = 0; i < outerPoints.Count; i++)
            {
                XYZ start = outerPoints[i];
                XYZ end = outerPoints[(i + 1) % outerPoints.Count];
                outerCurves.Add(Line.CreateBound(start, end));
            }

            // Create inner boundary (hole)
            List<Curve> innerCurves = new();
            for (int i = 0; i < innerPoints.Count; i++)
            {
                XYZ start = innerPoints[i];
                XYZ end = innerPoints[(i + 1) % innerPoints.Count];
                innerCurves.Add(Line.CreateBound(start, end));
            }

            // Create CurveArrArray with outer and inner loops
            var outerLoop = CurveLoop.Create(outerCurves);
            var innerLoop = CurveLoop.Create(innerCurves);

            var newCeiling = Ceiling.Create(doc, new List<CurveLoop> { outerLoop, innerLoop }, ceilingType.Id, level.Id);
            Parameter newCeilingParam = newCeiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            newCeilingParam.Set(ceilingHeight);

        }

        public Result DrawFirstFrame()
        {
            using (Transaction transaction = new Transaction(doc))
            {

                FailureHandlingOptions failureOptions = transaction.GetFailureHandlingOptions();
                failureOptions.SetFailuresPreprocessor(new WarningSwallower());
                transaction.SetFailureHandlingOptions(failureOptions);

                //// Configure transaction to suppress failure messages
                transaction.Start("Bad apple revit frame 1");

                var frame = loader.context.frames[0];
                var numBoundaries = frame.Rooms.Count;

                for (int i = 0; i < numBoundaries; i++)
                {
                    var room = frame.Rooms[i];

                    SubTransaction subTransaction = new SubTransaction(doc);
                    subTransaction.Start();

                    var startTime = DateTime.Now;
                    DrawSingleBoundary(room, doc);
                    var timeTaken = DateTime.Now - startTime;
                    lastTimeRun = DateTime.Now;

                    subTransaction.Commit();
                }

                transaction.Commit();
                //TaskDialog.Show(
                //    "Performance",
                //    $"Operation completed in:\n{timeTaken.TotalMilliseconds:F0} ms\n" +
                //    $"({timeTaken.TotalSeconds:F2} seconds)"
                //);
            }


            //transaction.Commit();


            return Result.Succeeded;
        }


        /// <summary>
        /// This gets the walltype when there are no instances
        /// </summary>
        /// <returns></returns>
        Wall GetWall()
        {
            var doc = BadApple.Application.ActiveUIDocument.Document;
            // Get a basic wall type
            return new FilteredElementCollector(doc)
                .OfClass(typeof(Wall))
                .FirstOrDefault(w => w.Name.Contains("Wall-Int")) as Wall;
        }


        public void Tick()
        {

        }

    }

    // Failure preprocessor to suppress warnings
    public class WarningSwallower : IFailuresPreprocessor
    {
        public FailureProcessingResult PreprocessFailures(FailuresAccessor failuresAccessor)
        {
            IList<FailureMessageAccessor> failures = failuresAccessor.GetFailureMessages();

            foreach (FailureMessageAccessor failure in failures)
            {
                FailureSeverity severity = failure.GetSeverity();

                if (severity == FailureSeverity.Warning)
                {
                    // Delete warnings
                    //failuresAccessor.DeleteWarning(failure);
                }
                else if (severity == FailureSeverity.Error)
                {
                    // For errors, try to resolve them by deleting the problematic elements
                    // or just continue and let Revit handle them

                    // Automatically delete the failing elements (same as clicking "Delete Instances")
                    //ICollection<ElementId> failingElementIds = failure.GetFailingElementIds();
                    //failuresAccessor.DeleteElements(failingElementIds.ToList());


                    //failure.SetCurrentResolutionType(FailureResolutionType.DeleteElements);

                    //failuresAccessor.ResolveFailure(failure);
                }
            }

            return FailureProcessingResult.Continue;
        }
    }

}
