using Autodesk.Revit.DB;
using Autodesk.Revit.DB.Architecture;
using Autodesk.Revit.UI;
using MatFileHandler;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public class BadAppleInstance
    {
        public MatLoader loader;
        public CameraAnimator animator;
        public int frameNum = 0;
        //public int endFrame = 1074;
        public int endFrame = int.MaxValue;


        public DateTime lastTimeRun;
        private Stopwatch frameTimer;
        private const double FRAME_INTERVAL_SECONDS = 0.1;

        RevitResources resources;
        public BadAppleInstance()
        {
            loader = new MatLoader();
            loader.Load();

            isRunning = true;
            animator = new CameraAnimator(loader.context.frames.Count);

            frameTimer = Stopwatch.StartNew();

            resources = BadApple.Resources;
        }

        // Mid run state
        List<ElementId> roomIds = new();
        List<ElementId> wallIds = new();
        List<ElementId> ceilingIds = new();

        public bool isRunning = false;

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

                Wall wall = Wall.Create(doc, wallLine, resources.wallType.Id, resources.level.Id, resources.wallHeight, 0, false, false);

                wallIds.Add(wall.Id);

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

                    Wall wall = Wall.Create(doc, wallLine, resources.wallType.Id, resources.level.Id, resources.wallHeight, 0, false, false);

                    wallIds.Add(wall.Id);

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


            // Not actually eneded for rendering even in 3d
            //var createdRoom = doc.Create.NewRoom(resources.level, uvPoint);
            //roomIds.Add(createdRoom.Id);

            var newCeiling = Ceiling.Create(doc, ceilingCurveLoops, resources.ceilingType.Id, resources.level.Id);
            Parameter newCeilingParam = newCeiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            newCeilingParam.Set(resources.ceilingHeight);
            ceilingIds.Add(newCeiling.Id);

            return Result.Succeeded;
        }

        public void UndoLastFrame()
        {
            //This doesnt work because the transaction managed object doesnt exist by a different command invocation
            //prevTransaction.RollBack();

            // Have to include this dll lib to get this to work
            ////UIFrameworkServices.QuickAccessToolBarService.performMultipleUndoRedoOperations(true, 1)

            //THis is using ids we had saved in the list 
            //var toDelete = roomIds.Concat(wallIds).Concat(ceilingIds);


            var doc = resources.doc;

            // Get all walls
            var walls = new FilteredElementCollector(doc)
                .OfClass(typeof(Wall))
                .Cast<Wall>()
                .Select(w => w.Id)
                .ToList();

            // Get all ceilings
            var ceilings = new FilteredElementCollector(doc)
                .OfClass(typeof(Ceiling))
                .Cast<Ceiling>()
                .Select(c => c.Id)
                .ToList();

            // Get all rooms
            var rooms = new FilteredElementCollector(doc)
                .OfClass(typeof(SpatialElement))
                .OfCategory(BuiltInCategory.OST_Rooms)
                .Select(r => r.Id)
                .ToList();

            // Combine all elements to delete
            var toDelete = walls.Concat(ceilings).Concat(rooms).ToList();


            Transaction transaction = new Transaction(resources.doc);
            transaction.Start("Removing prev frame items");

            if (toDelete.Count > 0)
            {
                doc.Delete(toDelete);
            }

            transaction.Commit();

            roomIds.Clear();
            wallIds.Clear();
            ceilingIds.Clear();
        }


        public Result DrawFirstFrame()
        {
            return DrawFrame(0);
        }

        public Result DrawFrame(int frameIndex)
        {
            using (Transaction transaction = new Transaction(resources.doc))
            {

                FailureHandlingOptions failureOptions = transaction.GetFailureHandlingOptions();
                failureOptions.SetFailuresPreprocessor(new WarningSwallower(this));
                transaction.SetFailureHandlingOptions(failureOptions);

                //// Configure transaction to suppress failure messages
                transaction.Start($"Bad apple revit frame {frameIndex + 1}");

                var frame = loader.context.frames[frameIndex];
                var numBoundaries = frame.Rooms.Count;

                for (int i = 0; i < numBoundaries; i++)
                {
                    var room = frame.Rooms[i];

                    SubTransaction subTransaction = new SubTransaction(resources.doc);
                    subTransaction.Start();

                    var startTime = DateTime.Now;
                    DrawSingleBoundary(room, resources.doc);
                    var timeTaken = DateTime.Now - startTime;
                    lastTimeRun = DateTime.Now;

                    subTransaction.Commit();
                }

                transaction.Commit();

                animator.Tick();

                //TaskDialog.Show(
                //    "Performance",
                //    $"Operation completed in:\n{timeTaken.TotalMilliseconds:F0} ms\n" +
                //    $"({timeTaken.TotalSeconds:F2} seconds)"
                //);
            }

            return Result.Succeeded;
        }

        public void Tick()
        {
            if (!isRunning)
                return;

            if (frameTimer == null)
            {
                return; // Not initialized yet
            }

            // Check if at least 0.5 seconds have passed since the last frame finished
            if (frameTimer.Elapsed.TotalSeconds >= FRAME_INTERVAL_SECONDS)
            {
                // Undo the current frame before drawing the next one
                // (DrawFirstFrame is called separately, so by the time Tick is called,
                // we always have a frame to undo before drawing the next)

                ScreenshotService.TakeCurrentFrameScreenshot();

                UndoLastFrame();

                //set endFrame to inf if we just want it to go to .mat end
                var lastFrame = Math.Min(endFrame, loader.context.frames.Count);

                if (frameNum + 1 >= lastFrame)
                {
                    frameTimer.Stop();
                    TaskDialog.Show("Finished all tframes!!!", "Done");
                    BadApple.Instance = null;
                    return;
                }

                frameNum++;
                DrawFrame(frameNum);


                frameTimer.Restart();
            }
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

            var newCeiling = Ceiling.Create(resources.doc, new List<CurveLoop> { outerLoop, innerLoop }, resources.ceilingType.Id, resources.level.Id);
            Parameter newCeilingParam = newCeiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            newCeilingParam.Set(resources.ceilingHeight);

        }

    }

    // Failure preprocessor to suppress warnings
    public class WarningSwallower : IFailuresPreprocessor
    {
        private readonly BadAppleInstance _instance;

        public WarningSwallower(BadAppleInstance instance)
        {
            _instance = instance;
        }

        public FailureProcessingResult PreprocessFailures(FailuresAccessor failuresAccessor)
        {
            IList<FailureMessageAccessor> failures = failuresAccessor.GetFailureMessages();
            bool forceCommit = false;

            foreach (FailureMessageAccessor failure in failures)
            {
                FailureSeverity severity = failure.GetSeverity();
                var failureId = failure.GetFailureDefinitionId();


                if (severity == FailureSeverity.Warning)
                {

                    // Delete unwanted warnings
                    //https://www.revitapidocs.com/2016/c0b6a1e7-ac2c-daaf-031b-b7b1fa946d32.htm
                    //These are not compile time constants so we cant use a switch statement on em

                    if (failureId == BuiltInFailures.InaccurateFailures.InaccurateSketchLine)
                    {
                        failuresAccessor.DeleteWarning(failure);
                        continue;

                    }
                    if (failureId == BuiltInFailures.InaccurateFailures.InaccurateWall)
                    {
                        failuresAccessor.DeleteWarning(failure);
                        continue;
                    }
                    if (failureId == BuiltInFailures.OverlapFailures.WallsOverlap)
                    {
                        failuresAccessor.DeleteWarning(failure);
                        continue;
                    }
                    var error = failure.GetDescriptionText();
                    Console.WriteLine($"fucked up: {error}");
                }
                else if (severity == FailureSeverity.Error)
                {
                    // For errors, try to resolve them by deleting the problematic elements
                    // or just continue and let Revit handle them

                    // Automatically delete the failing elements (same as clicking "Delete Instances")
                    //ICollection<ElementId> failingElementIds = failure.GetFailingElementIds();
                    //failuresAccessor.DeleteElements(failingElementIds.ToList());


                    if (failureId == BuiltInFailures.JoinElementsFailures.CannotJoinElementsError)
                    {
                        failure.SetCurrentResolutionType(FailureResolutionType.DetachElements);
                        failuresAccessor.ResolveFailure(failure);
                        forceCommit = true;
                    }
                    if (failureId == BuiltInFailures.CreationFailures.CannotDrawWallsError)
                    {
                        failure.SetCurrentResolutionType(FailureResolutionType.DeleteElements);
                        failuresAccessor.ResolveFailure(failure);
                        forceCommit = true;
                    }


                    //If we get here, perhaps just undo and force the next run to rerun the current frame and try with a different wallthickness
                }
            }

            if (forceCommit)
            {
                return FailureProcessingResult.ProceedWithCommit;
            }
            else
            {
                return FailureProcessingResult.Continue;
            }
        }
    }
}
