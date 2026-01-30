using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using MatFileHandler;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace BadRevitPlugin
{
    public class MatLoader
    {
        public MatLoader()
        {

        }

        public ICellArray boundaries = null;
        public ICellArray centroids = null;

        public void Load()
        {
            string cwd = System.IO.Directory.GetCurrentDirectory();
            Console.WriteLine($"Current Working Directory: {cwd}");

            // Might have to use this since mat will be located relative to this
            string assemblyWorkingDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            Console.WriteLine($"Current Working Directory: {assemblyWorkingDir}");

            //TaskDialog.Show("Current Working Dir", cwd);
            //TaskDialog.Show("Assembly Working Dir", otherworkingDir);

            var matRelativeLoc = "../../../../../bad_apple.mat";

            var matFileLoc = Path.Combine(assemblyWorkingDir, matRelativeLoc);
            matFileLoc = Path.GetFullPath(matFileLoc);

            TaskDialog td = new TaskDialog("Mat File Location");
            td.MainInstruction = "Material file path:";
            td.MainContent = "Click 'Show Details' to view full path.";
            td.ExpandedContent = matFileLoc;

            //td.Show();


            IMatFile matFile;
            using (var fileStream = new System.IO.FileStream(matFileLoc, System.IO.FileMode.Open))
            {
                var reader = new MatFileReader(fileStream);
                matFile = reader.Read();
            }

            var frameCount = matFile["num_frames"].Value.ConvertToDoubleArray()[0];
            boundaries = matFile["simple_bounds"].Value as ICellArray;
            centroids = matFile["centroids"].Value as ICellArray;

            IArrayOf<double> firstFrameBoundary = boundaries[0, 0] as IArrayOf<double>;


            Console.WriteLine("Sup");
        }
    }

    public class RoomBoundary
    {
        public List<XYZ> MainOuterLoop = new();
        public List<List<XYZ>> InnerLoops = new();

        public static RoomBoundary Create(IArrayOf<double> points)
        {
            var room = new RoomBoundary();
            return room;
        }
    }

    public class BadAppleFrame
    {
        public List<RoomBoundary> Rooms = new();

        public static BadAppleFrame Create(ICellArray cellArray)
        {
            var frame = new BadAppleFrame();
            return frame;
        }
    }

    public class BadAppleContext
    {
        public List<BadAppleFrame> frames = new();
    }
}
