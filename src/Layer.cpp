
#include "Layer.h"
#include "FileManager.h"

#include "CompoundImage.h"
#include "ResampledImage.h"

#include <cmath>
#include "Logger.h"

#define EPS 1./256.

Image* Layer::getbbox(BoundingBox<double> bbox, int width, int height) {
  // On convertit les coordonnées en nombre de pixels depuis l'origine X0,Y0  
  bbox.xmin = (bbox.xmin - X0)/resolution_x;
  bbox.xmax = (bbox.xmax - X0)/resolution_x;
  double tmp = bbox.ymin;
  bbox.ymin = (Y0 - bbox.ymax)/resolution_y;
  bbox.ymax = (Y0 - tmp)/resolution_y;

//A VERIFIER !!!!

  BoundingBox<int64_t> bbox_int(floor(bbox.xmin + EPS),
                                floor(bbox.ymin + EPS), 
                                ceil(bbox.xmax - EPS),
                                ceil(bbox.ymax - EPS));
  
  if(bbox_int.xmax - bbox_int.xmin == width && bbox_int.ymax - bbox_int.ymin == height && 
     bbox.xmin - bbox_int.xmin < EPS && bbox.ymin - bbox_int.ymin < EPS &&
     bbox_int.xmax - bbox.xmax < EPS && bbox_int.ymax - bbox.ymax < EPS) {
    return getwindow(bbox_int);
  }

  double ratio_x = (bbox.xmax - bbox.xmin) / width;
  double ratio_y = (bbox.ymax - bbox.ymin) / height;

  bbox_int.xmin = floor(bbox.xmin - Lanczos<2>::size(ratio_x));
  bbox_int.xmax = ceil (bbox.xmax + Lanczos<2>::size(ratio_x));
  bbox_int.ymin = floor(bbox.ymin - Lanczos<2>::size(ratio_y));
  bbox_int.ymax = ceil (bbox.ymax + Lanczos<2>::size(ratio_y));   
  return new ResampledImage<Lanczos<2> >(getwindow(bbox_int), width, height, bbox.xmin - bbox_int.xmin, bbox.ymin - bbox_int.ymin, ratio_x, ratio_y);
//    return new ResampledImage<NearestNeighbour>(getwindow(bbox_int), width, height, bbox.xmin - bbox_int.xmin, bbox.ymin - bbox_int.ymin, ratio_x, ratio_y);
}


template<class Decoder>
Image* TiledLayer<Decoder>::getwindow(BoundingBox<int64_t> bbox) {

  int tile_xmin = bbox.xmin / tile_width;
  int tile_xmax = (bbox.xmax -1)/ tile_width;
  int nbx = tile_xmax - tile_xmin + 1; 
  LOGGER(DEBUG) << " getwindow " << tile_xmin << " " << tile_xmax << " " << nbx << " " << tile_width << " " << std::endl; 

  int tile_ymin = bbox.ymin / tile_height;
  int tile_ymax = (bbox.ymax-1) / tile_height;
  int nby = tile_ymax - tile_ymin + 1;

  int left[nbx];   memset(left, 0, nbx*sizeof(int));   left[0] = bbox.xmin % tile_width;
  int top[nby];    memset(top, 0, nby*sizeof(int));    top[0] = bbox.ymin % tile_height;
  int right[nbx];  memset(right, 0, nbx*sizeof(int));  right[nbx - 1] = tile_width - ((bbox.xmax -1) % tile_width) - 1;
  int bottom[nby]; memset(bottom, 0, nby*sizeof(int)); bottom[nby - 1] = tile_height - ((bbox.ymax -1) % tile_height) - 1;

  std::vector<std::vector<Image*> > T(nby, std::vector<Image*>(nbx));
  for(int y = 0; y < nby; y++)
    for(int x = 0; x < nbx; x++) {
      LOGGER(DEBUG) << " getwindow " << x << " " << y << " " << nbx << " " << nby << " " << left[x] << " " << right[x] << " " << top[y] << " " << bottom[y] << std::endl;      
      StaticHttpResponse* tile = gettile(tile_xmin + x, tile_ymin + y);
      T[y][x] = new Tile<Decoder>(tile_width, tile_height, channels, tile, left[x], top[y], right[x], bottom[y]);
    }

  if(nbx == 1 && nby == 1) return T[0][0];
  else return new CompoundImage(T);
}






/*
 * Tableau statique des caractères Base64 (pour système de fichier)
 */
static const char* Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-";

/*
 *
 *
 */
template<class Decoder>
std::string TiledLayer<Decoder>::getfilepath(int tilex, int tiley) {
  LOGGER(DEBUG) << " getfilepath " << tilex << " " << tiley << std::endl;

  int x = tilex / tiles_per_width;
  int y = tiley / tiles_per_height;
  char path[32];
  path[sizeof(path) - 5] = '.';
  path[sizeof(path) - 4] = 't';
  path[sizeof(path) - 3] = 'i';
  path[sizeof(path) - 2] = 'f';
  path[sizeof(path) - 1] = 0;
  int pos = sizeof(path) - 6;

  for(int d = 0; d < path_depth; d++) {
    path[pos--] = Base64[y & 63];
    path[pos--] = Base64[x & 63];
    path[pos--] = '/';
    x >>= 6;
    y >>= 6;
  }
  do {
    path[pos--] = Base64[y & 63];
    path[pos--] = Base64[x & 63];
    x >>= 6;
    y >>= 6;
  } while(x || y);
  path[pos] = '/';

  LOGGER(DEBUG) << " getfilepath " << (path +pos)<< std::endl;


  return basedir + (path + pos);
}


template<class Decoder>
StaticHttpResponse* TiledLayer<Decoder>::gettile(int x, int y) 
{
  LOGGER(DEBUG) << " TiledLayer: gettile " << x << " " << y << std::endl;  
  
  if(x < 0 || y < 0) {
    data_t* T = new data_t[tile_width*tile_height*channels];    
    return new StaticHttpResponse("bubu", T, tile_width*tile_height*channels*sizeof(data_t));
  }

  std::string file_path = getfilepath(x, y);

//  LOGGER(DEBUG) << " TiledLayer: gettile " << file_path << std::endl;  

  uint32_t size;
  int n=(y%tiles_per_height)*tiles_per_width + (x%tiles_per_width); // Index de la tuile
  uint32_t posoff=1024+4*n, possize=1024+4*n +tiles_per_width*tiles_per_height*4;

  LOGGER(DEBUG) << " TiledLayer: gettile " << posoff << " " <<  possize << std::endl;  
  const uint8_t *data = FileManager::gettile(file_path, size, posoff, possize);
  LOGGER(DEBUG) << " TiledLayer: gettile " << size << std::endl;  

  if(data) return new StaticHttpResponse("bubu", data, size);
  else {
    LOGGER(DEBUG) << " TiledLayer: gettile " << size << std::endl;

    data_t* T = new data_t[tile_width*tile_height*channels];    
    return new StaticHttpResponse("bubu", T, tile_width*tile_height*channels*sizeof(data_t));
  }
}




template class TiledLayer<RawDecoder>;
//template class Layer<pixel_gray>;
//template class Layer<pixel_float>;

//template class TiledFileLayer<RawTile ,pixel_rgb>;
//template class TiledFileLayer<RawTile ,pixel_float>;
//template class TiledFileLayer<PngTile ,pixel_rgb>;
//template class TiledFileLayer<JpegTile,pixel_rgb>;

//template class TiledFileLayer<RawTile ,pixel_gray>;
//template class TiledFileLayer<PngTile ,pixel_gray>;
//template class TiledFileLayer<JpegTile,pixel_gray>;


/*
template class TiledFileLayer<pixel_rgb>;
template class RawTiffLayer<pixel_rgb>;
template class JpegTiffLayer<pixel_rgb>;
template class PngTiffLayer<pixel_gray>;
*/



