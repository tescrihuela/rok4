/**
* \file Rok4Api.cpp
* \brief Implementation de l'API de ROK4
*/

#include "Rok4Api.h"
#include "config.h"
#include <proj_api.h>
#include "ConfLoader.h"
#include "Message.h"
#include "Request.h"

/**
* @brief Initialisation d'une reponse a partir d'une source
* @brief Les donnees source sont copiees dans la reponse
*/

HttpResponse* initResponseFromSource(DataSource* source){
        HttpResponse* response=new HttpResponse;
        response->status=source->getHttpStatus();
        response->type=new char[source->getType().length()+1];
        strcpy(response->type,source->getType().c_str());
        size_t buffer_size;
        const uint8_t *buffer = source->getData(buffer_size);
	// TODO : tester sans copie memoire (attention, la source devrait etre supprimee plus tard)

        response->content=new char[buffer_size+1];
        strcpy(response->content,(char*)buffer);
        return response;
}

/**
* @brief Finder pour utiliser la fonction callback pj_set_finder de la libproj
*/

char PROJ_LIB[1024] = PROJ_LIB_PATH;
const char *pj_finder(const char *name) {
  strcpy(PROJ_LIB + 15, name);
  return PROJ_LIB;
}

/**
* @brief Initialisation du serveur ROK4
* @param serverConfigFile : nom du fichier de configuration des parametres techniques
* @return : pointeur sur le serveur ROK4, NULL en cas d'erreur (forcement fatale)
*/

Rok4Server* rok4InitServer(const char* serverConfigFile){
	// Initialisation de l'acces au parametrage de la libproj
	pj_set_finder( pj_finder );

	// Initialisation des parametres techniques
	int nbThread,logFilePeriod;
	std::string strServerConfigFile=serverConfigFile,strLogFileprefix,strServicesConfigFile,strLayerDir,strTmsDir;
	if (!ConfLoader::getTechnicalParam(strServerConfigFile, strLogFileprefix, logFilePeriod, nbThread, strServicesConfigFile, strLayerDir, strTmsDir)){
		std::cerr<<"ERREUR FATALE : Impossible d'interpreter le fichier de configuration du serveur "<<strServerConfigFile<<std::endl;
		return false;
	}

	//Initialisation du logger
	RollingFileAccumulator* acc = new RollingFileAccumulator(strLogFileprefix,logFilePeriod);
	Logger::setAccumulator(DEBUG, acc);
        Logger::setAccumulator(INFO , acc);
        Logger::setAccumulator(WARN , acc);
        Logger::setAccumulator(ERROR, acc);
        Logger::setAccumulator(FATAL, acc);
	std::ostream &log = LOGGER(DEBUG);
        log.precision(8);
        log.setf(std::ios::fixed,std::ios::floatfield);
	std::cout<<"Envoi des messages dans la sortie du logger"<< std::endl;
        LOGGER_INFO("*** DEBUT DU FONCTIONNEMENT DU LOGGER ***");

	// Construction des parametres de service
	ServicesConf* servicesConf=ConfLoader::buildServicesConf(strServicesConfigFile);
	if (servicesConf==NULL){
		LOGGER_FATAL("Impossible d'interpreter le fichier de conf "<<strServicesConfigFile);
                LOGGER_FATAL("Extinction du serveur ROK4");
		sleep(1);	// Pour laisser le temps au logger pour se vider	
		return NULL;
	}

	// Chargement des TMS
	std::map<std::string,TileMatrixSet*> tmsList;
	if (!ConfLoader::buildTMSList(strTmsDir,tmsList)){
		LOGGER_FATAL("Impossible de charger la conf des TileMatrix");
                LOGGER_FATAL("Extinction du serveur ROK4");
		sleep(1);       // Pour laisser le temps au logger pour se vider
		return NULL;
	}
	
	// Chargement des layers
	std::map<std::string, Layer*> layerList;
	if (!ConfLoader::buildLayersList(strLayerDir,tmsList,layerList)){
		LOGGER_FATAL("Impossible de charger la conf des Layers/pyramides");
                LOGGER_FATAL("Extinction du serveur ROK4");
		sleep(1);       // Pour laisser le temps au logger pour se vider
		return NULL;
	}

	// Instanciation du serveur
	return new Rok4Server(nbThread, *servicesConf, layerList, tmsList);
}

/**
* @brief Implementation de l'operation GetCapabilities pour le WMTS
* @param query
* @param hostname
* @param path
* @brief Les variables sont allouees et doivent etre desallouees ensuite. 
* @param server : serveur
* @return Reponse
*/

HttpResponse* rok4GetWMTSCapabilities(const char* hostname, const char* path, Rok4Server* server){
        Request* request=new Request(0,(char*)hostname,(char*)path);
	DataStream* stream=server->WMTSGetCapabilities(request);
	HttpResponse* response=initResponseFromSource(new BufferedDataSource(*stream));
	delete request;
	delete stream;
	return response;
}

/**
* @brief Implementation de l'operation GetTile
* @param query
* @param hostname
* @param path
* Exemple :
* http://localhost/target/bin/rok4?SERVICE=WMTS&REQUEST=GetTile&tileCol=6424&tileRow=50233&tileMatrix=19&LAYER=ORTHO_RAW_IGNF_LAMB93&STYLES=&FORMAT=image/tiff&DPI=96&TRANSPARENT=TRUE&TILEMATRIXSET=LAMB93_10cm&VERSION=1.0.0
* query="SERVICE=WMTS&REQUEST=GetTile&tileCol=6424&tileRow=50233&tileMatrix=19&LAYER=ORTHO_RAW_IGNF_LAMB93&STYLES=&FORMAT=image/tiff&DPI=96&TRANSPARENT=TRUE&TILEMATRIXSET=LAMB93_10cm&VERSION=1.0.0"
* hostname="localhost"
* path="/target/bin/rok4"
* @param server : serveur
* @return Reponse
*/

HttpResponse* rok4GetTile(const char* query, const char* hostname, const char* path, Rok4Server* server){
        std::string strQuery=query;
        Request* request=new Request((char*)strQuery.c_str(),(char*)hostname,(char*)path);
	DataSource* source=server->getTile(request);
	HttpResponse* response=initResponseFromSource(source);
	delete request;
        delete source;
        return response;
}

/**
* @brief Implementation de l'operation GetTile modifiee
* @brief La tuile n'est pas lue, les elements recuperes sont les references de la tuile : le fichier dans lequel elle est stockee et les positions d'enregistrement(sur 4 octets) dans ce fichier de l'index du premier octet de la tuile et de sa taille
* @param query
* @param hostname
* @param path
* @param server : serveur
* @param filename : nom du fichier
* @param posoff : position d'enregistrement de l'offset de la tuile
* @param possize : position d'enregistrement de la taille de la tuile
* @return Reponse en cas d'exception, NULL sinon
*/

HttpResponse* rok4GetTileReferences(const char* query, const char* hostname, const char* path, Rok4Server* server, char** filename, uint32_t* posoff, uint32_t* possize){
	// Initialisation
	std::string strQuery=query;

	Request* request=new Request((char*)strQuery.c_str(),(char*)hostname,(char*)path);
	Layer* layer;
        std::string tmId,format;
        int x,y;

	// Analyse de la requete
        DataSource* errorResp = request->getTileParam(server->getServicesConf(), server->getTmsList(), server->getLayerList(), layer, tmId, x, y, format);
	// Exception
        if (errorResp){
                LOGGER_ERROR("Probleme dans les parametres de la requete getTile");
		HttpResponse* error=initResponseFromSource(errorResp);
		delete errorResp;
		return error;
        }

	// References de la tuile
	// TODO : controler l existence du level

	Level* level=layer->getPyramids()[0]->getLevels().find(tmId)->second;
	int n=(y%level->getTilesPerHeight())*level->getTilesPerWidth() + (x%level->getTilesPerWidth());
        *posoff=2048+4*n;
	*possize=2048+4*n +level->getTilesPerWidth()*level->getTilesPerHeight()*4;
        std::string imageFilePath=level->getFilePath(x, y);
	*filename=new char[imageFilePath.length()+1];
	strcpy(*filename,imageFilePath.c_str());

	delete request;
	return 0;
}

/**
* @brief Extinction du serveur
*/

void rok4KillServer(Rok4Server* server){
        LOGGER_INFO( "Extinction du serveur ROK4");

        std::map<std::string,TileMatrixSet*>::iterator iTms;
        for (iTms=server->getTmsList().begin();iTms!=server->getTmsList().end();iTms++)
                delete (*iTms).second;

        std::map<std::string, Layer*>::iterator iLayer;
        for (iLayer=server->getLayerList().begin();iLayer!=server->getLayerList().end();iLayer++)
                delete (*iLayer).second;

	// TODO Supprimer le logger
}
