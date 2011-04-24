using System;
using System.Text;
using System.Drawing;
using System.IO;

namespace SeaDragonLand
{
    class Program
    {
        static void Main(string[] args)
        {
            Bitmap bmp = new Bitmap("LandscapeTiles.png");

            const int LandscapeTileCount = 16 * 6;

            FileStream fs = new FileStream("tileland.inc", FileMode.Create);
            StreamWriter writer = new StreamWriter(fs);
            writer.WriteLine("; Sea Dragon for GameBoy");
            writer.WriteLine("; Landscape tiles");
            writer.WriteLine();
            writer.WriteLine("        PUSHO");
            writer.WriteLine("; Define . and X to be 0 and 1");
            writer.WriteLine("        OPT     b.X");
            writer.WriteLine();
            writer.WriteLine("LandscapeTileCount\tEQU\t{0}", LandscapeTileCount);
            writer.WriteLine();
            writer.WriteLine("LandscapeTiles:");

            for (int tile = 0; tile < LandscapeTileCount; tile++)
            {
                int tileno = tile + 128;
                writer.WriteLine("; Tile {0} = ${0:X}", tileno);
                int left = (tile % 16) * 8;
                int top = (tile / 16) * 8;
                for (int y = 0; y < 8; y++)
                {
                    writer.Write("\tDB\t%");
                    for (int x = 0; x < 8; x++)
                    {
                        Color cr = bmp.GetPixel(x + left, y + top);
                        char ch = ((int)cr.R + (int)cr.G + (int)cr.B) > 150*3 ? '.' : 'X';
                        writer.Write(ch);
                    }
                    writer.WriteLine();
                }
            }

            writer.WriteLine();
            writer.WriteLine("        POPO");
            writer.WriteLine();
            writer.Close();
        }
    }
}
