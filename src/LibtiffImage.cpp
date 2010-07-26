#include "LibtiffImage.h"
#include "Logger.h"
#include "Convert.h"

/**
Creation d'une LibtiffImage a partir d un fichier TIFF filename
retourne NULL en cas d erreur
*/

LibtiffImage* libtiffImageFactory::createLibtiffImage(char* filename)
{
	int width=0,height=0,channels=0,planarconfig=0; 
	double x0,y0,resx,resy;
        TIFF* tif=TIFFOpen(filename, "r");
        if (tif==NULL)
        {
                LOGGER_DEBUG( "Impossible d ouvrir " << filename);
		return NULL;
        }
        else
        {
                if (TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &width)<1)
		{
                        LOGGER_DEBUG( "Impossible de lire la largeur de " << filename);
			return NULL;
		}
                if (TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &height)<1)
		{
                        LOGGER_DEBUG( "Impossible de lire la hauteur de " << filename);
			return NULL;
		}
                if (TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL,&channels)<1)
		{
                        LOGGER_DEBUG( "Impossible de lire le nombre de canaux de " << filename);
			return NULL;
		}
                if (TIFFGetField(tif, TIFFTAG_PLANARCONFIG,&planarconfig)<1)
		{
                        LOGGER_DEBUG( "Impossible de lire la configuration des plans de " << filename);
			return NULL;
		}
        }

	if (width*height*channels!=0 && planarconfig!=PLANARCONFIG_CONTIG && tif!=NULL)
		return NULL;	

	return new LibtiffImage(width,height,channels,x0,y0,resx,resy,tif);
}

LibtiffImage::LibtiffImage(int width,int height, int channels, double x0, double y0, double resx, double resy, TIFF* tif) : GeoreferencedImage(width,height,channels,x0,y0,resx,resy), tif(tif)
{
}

int LibtiffImage::getline(uint8_t* buffer, int line)
{
// le buffer est déjà alloue
// Cas RGB : canaux entralaces (TIFFTAG_PLANARCONFIG=PLANARCONFIG_CONTIG)
	TIFFReadScanline(tif,buffer,line,0);	
	return width*channels;
}

int LibtiffImage::getline(float* buffer, int line)
{
	uint8_t* buffer_t = new uint8_t[width*channels];
	getline(buffer_t,line);
	convert(buffer,buffer_t,width*channels);
	delete [] buffer_t;
        return width*channels;
}

LibtiffImage::~LibtiffImage()
{
//	if (tif)
//		TIFFClose(tif);
//	LOGGER_DEBUG("Destructeur LibtiffImage");

}