#ifndef _ROK4SERVER_
#define _ROK4SERVER_

/**
* \file Rok4Server.h
* \brief Definition de la classe Rok4Server et programme principal
*/

#include "config.h"
#include "ResponseSender.h"
#include "Data.h"
#include "Request.h"
#include <pthread.h>
#include <map>
#include <vector>
#include "ServicesConf.h"
#include "Layer.h"
#include "TileMatrixSet.h"
#include "fcgiapp.h"

/**
* \class Rok4Server 
*
*/

class Rok4Server {
private:
	std::vector<pthread_t> threads;
	ResponseSender S;

	int sock;

	ServicesConf servicesConf;
	std::map<std::string, Layer*> layerList;
	std::map<std::string, TileMatrixSet*> tmsList;
        std::vector<std::string> wmsCapaFrag;  /// liste des fragments invariants de capabilities prets à être concaténés avec les infos de la requête.
        std::vector<std::string> wmtsCapaFrag; /// liste des fragments invariants de capabilities prets à être concaténés avec les infos de la requête.

	static void* thread_loop(void* arg);

	void buildWMSCapabilities();
	void buildWMTSCapabilities();

	DataStream* getMap (Request* request);
	DataStream* WMSGetCapabilities (Request* request);
	void        processWMS    (Request *request, FCGX_Request&  fcgxRequest);
	void        processWMTS   (Request *request, FCGX_Request&  fcgxRequest);
	void        processRequest(Request *request, FCGX_Request&  fcgxRequest);

public:
	ServicesConf& getServicesConf() {return servicesConf;}
	std::map<std::string, Layer*>& getLayerList() {return layerList;}
	std::map<std::string, TileMatrixSet*>& getTmsList() {return tmsList;}
	std::vector<std::string>& getWmsCapaFrag() {return wmsCapaFrag;}
	std::vector<std::string>& getWmtsCapaFrag() {return wmtsCapaFrag;}
	DataSource* getTile(Request* request);
	DataStream* WMTSGetCapabilities(Request* request);

	void run();
	Rok4Server(int nbThread, ServicesConf& servicesConf, std::map<std::string,Layer*> &layerList, std::map<std::string,TileMatrixSet*> &tmsList);

};

#endif

