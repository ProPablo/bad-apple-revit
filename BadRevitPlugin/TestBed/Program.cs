using BadRevitPlugin;

public class Program
{
    private static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
        var loader = new MatLoader();
        loader.Load();
    }
}