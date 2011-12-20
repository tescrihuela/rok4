#ifndef LEVEL_H
#define LEVEL_H

#include "Image.h"
#include "BoundingBox.h"
#include "TileMatrix.h"
#include "Data.h"
#include "FileDataSource.h"
#include "CRS.h"
#include "format.h"

/**
 */

class Level {
private:

	std::string   baseDir;
	int           pathDepth;
	TileMatrix    tm;         // FIXME j'ai des problème de compil que je ne comprends pas si je mets un const ?!
	const eformat_data format; //format d'image des tuiles
	const int     channels;
	const int32_t maxTileRow;
	const int32_t minTileRow;
	const int32_t maxTileCol;
	const int32_t minTileCol;
	uint32_t      tilesPerWidth;   //nombre de tuiles par dalle dans le sens de la largeur
	uint32_t      tilesPerHeight;  //nombre de tuiles par dalle dans le sens de la hauteur
	std::string noDataFile;
	DataSource* noDataSource;
	
	DataSource* getEncodedTile(int x, int y);
	DataSource* getDecodedTile(int x, int y);
	DataSource* getEncodedNoDataTile();
	

protected:
	/**
	 * Renvoie une image de taille width, height
	 *
	 * le coin haut gauche de cette image est le pixel offsetx, offsety de la tuile tilex, tilex.
	 * Toutes les coordonnées sont entière depuis le coin haut gauche.
	 */
	Image* getwindow(BoundingBox<int64_t> src_bbox);


public:
	TileMatrix getTm(){return tm;}
	eformat_data getFormat(){return format;}
	int	    getChannels(){return channels;}
	uint32_t    getMaxTileRow(){return maxTileRow;}
	uint32_t    getMinTileRow(){return minTileRow;}
	uint32_t    getMaxTileCol(){return maxTileCol;}
	uint32_t    getMinTileCol(){return minTileCol;}
	double      getRes(){return tm.getRes();}
	std::string getId(){return tm.getId();}
	uint32_t      getTilesPerWidth(){return tilesPerWidth;}
	uint32_t      getTilesPerHeight(){return tilesPerHeight;}

	std::string getFilePath(int tilex, int tiley);
	std::string getNoDataFilePath(){return noDataFile;}

	Image* getbbox(BoundingBox<double> bbox, int width, int height);

	Image* getbbox(BoundingBox<double> bbox, int width, int height, CRS src_crs, CRS dst_crs);
	/**
	 * Renvoie la tuile x, y numéroté depuis l'origine.
	 * Le coin haut gauche de la tuile (0,0) est (Xorigin, Yorigin)
	 * Les indices de tuiles augmentes vers la droite et vers le bas.
	 * Des indices de tuiles négatifs sont interdits
	 *
	 * La tuile contenant la coordonnées (X, Y) dans le srs d'origine a pour indice :
	 * x = floor((X - X0) / (tile_width * resolution_x))
	 * y = floor((Y - Y0) / (tile_height * resolution_y))
	 */
	
	DataSource* getTile(int x, int y);

	Image* getTile(int x, int y, int left, int top, int right, int bottom);

	void setNoData(const std::string& file) {noDataFile=file;}
	void setNoDataSource(DataSource* source) {noDataSource=source;}
	
	/** D */
	Level(TileMatrix tm, int channels, std::string baseDir,
			int tilesPerWidth, int tilesPerHeight,
			uint32_t maxTileRow, uint32_t minTileRow, uint32_t maxTileCol, uint32_t minTileCol,
			int pathDepth, eformat_data format, std::string noDataFile) : tm(tm), channels(channels), baseDir(baseDir), tilesPerWidth(tilesPerWidth), tilesPerHeight(tilesPerHeight), maxTileRow(maxTileRow), minTileRow(minTileRow), maxTileCol(maxTileCol), minTileCol(minTileCol), pathDepth(pathDepth), format(format),noDataFile(noDataFile){}

	/*
	 * Destructeur
	 */
	~Level(){}

};

#endif





