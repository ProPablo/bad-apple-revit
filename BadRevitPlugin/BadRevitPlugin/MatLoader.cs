using MatFileHandler;
using System;
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

        public void Load()
        {
            int sup = 5;


            string cwd = System.IO.Directory.GetCurrentDirectory();
            Console.WriteLine($"Current Working Directory: {cwd}");

            // Might have to use this since mat will be located relative to this
            string otherworkingDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            Console.WriteLine($"Current Working Directory: {otherworkingDir}");


            IMatFile matFile;
            using (var fileStream = new System.IO.FileStream("../../../../../bad_apple.mat", System.IO.FileMode.Open))
            {
                var reader = new MatFileReader(fileStream);
                matFile = reader.Read();
            }
            
            var frameCount = matFile["num_frames"].Value.ConvertToDoubleArray()[0];
            boundaries = matFile["simple_bounds"].Value as ICellArray;

            IArrayOf<double> firstFrameBoundary = boundaries[0, 0] as IArrayOf<double>;


            Console.WriteLine("Sup");
        }
    }
}
