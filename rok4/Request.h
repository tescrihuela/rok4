#ifndef REQUEST_H_
#define REQUEST_H_

#include <map>
#include "BoundingBox.h"
#include "Data.h"
#include "CRS.h"
#include "Layer.h"
#include "ServicesConf.h"

/**
* @brief Classe request
* @brief Decodage d'une requete HTTP
*/

class Request {
private:
	void url_decode(char *src);
	std::string getParam(std::string paramName);
	
public:
	std::string hostName;
	std::string path;
	std::string service;
	std::string request;
	std::string scheme;
	std::map<std::string, std::string> params;
	DataSource* getTileParam(ServicesConf& servicesConf,  std::map<std::string,TileMatrixSet*>& tmsList, std::map<std::string, Layer*>& layerList, Layer*& layer, std::string &tileMatrix, int &tileCol, int &tileRow, std::string  &format);
	DataStream* getMapParam(ServicesConf& servicesConf, std::map<std::string, Layer*>& layerList, Layer*& layer, BoundingBox<double> &bbox, int &width, int &height, CRS& crs, std::string &format);

	Request(char* strquery, char* hostName, char* path, char* https);
	virtual ~Request();
};

#endif /* REQUEST_H_ */
