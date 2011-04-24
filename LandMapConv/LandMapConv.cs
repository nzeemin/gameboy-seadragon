using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using System.IO;

namespace SeaDragonTiler
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.Out.WriteLine("Usage: SeaDragonTiler <inputfile.tmx> <outfile>");
                Environment.Exit(255);
            }

            string filename = args[0];
            string outfilename = args[1];

            XmlDocument xml = new XmlDocument();
            xml.Load(filename);
            //XmlNode root = xml.SelectSingleNode("/map");
            XmlNode node = xml.SelectSingleNode("/map/layer/data");
            string base64str = node.InnerText.Trim();
            byte[] data = Convert.FromBase64String(base64str);
            int columns = data.Length / 4 / 15;

            FileStream fs = new FileStream(outfilename, FileMode.Create);
            StreamWriter writer = new StreamWriter(fs);
            writer.WriteLine();

            for (int col = 0; col < columns; col++)
            {
                writer.Write("\tDB\t");
                for (int row = 0; row < 15; row++)
                {
                    byte ch = (byte)(data[(row * columns + col) * 4] - 1);
                    if (row > 0) writer.Write(",");
                    writer.Write("${0:X2}", ch);
                }
                writer.WriteLine();
            }

            writer.WriteLine();
            writer.Close();
        }
    }
}
