# Copyright © (2011) Institut national de l'information
#                    géographique et forestière 
# 
# Géoportail SAV <geop_services@geoportail.fr>
# 
# This software is a computer program whose purpose is to publish geographic
# data using OGC WMS and WMTS protocol.
# 
# This software is governed by the CeCILL-C license under French law and
# abiding by the rules of distribution of free software.  You can  use, 
# modify and/ or redistribute the software under the terms of the CeCILL-C
# license as circulated by CEA, CNRS and INRIA at the following URL
# "http://www.cecill.info". 
# 
# As a counterpart to the access to the source code and  rights to copy,
# modify and redistribute granted by the license, users are provided only
# with a limited warranty  and the software's author,  the holder of the
# economic rights,  and the successive licensors  have only  limited
# liability. 
# 
# In this respect, the user's attention is drawn to the risks associated
# with loading,  using,  modifying and/or developing or reproducing the
# software by the user in light of its specific status of free software,
# that may mean  that it is complicated to manipulate,  and  that  also
# therefore means  that it is reserved for developers  and  experienced
# professionals having in-depth computer knowledge. Users are therefore
# encouraged to load and test the software's suitability as regards their
# requirements in conditions enabling the security of their systems and/or 
# data to be ensured and,  more generally, to use and operate it in the 
# same conditions as regards security. 
# 
# The fact that you are presently reading this means that you have had
# 
# knowledge of the CeCILL-C license and that you accept its terms.

package BE4::DataSourceLoader;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use Data::Dumper;
use List::Util qw(min max);

use Data::Dumper;
use Geo::GDAL;

# My module
use BE4::DataSource;
use BE4::PropertiesLoader;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{$EXPORT_TAGS{'all'}} );
our @EXPORT      = qw();

################################################################################
# Constantes
use constant TRUE  => 1;
use constant FALSE => 0;

################################################################################
# Global
my %SOURCE;

################################################################################

BEGIN {}
INIT {}
END {}

################################################################################
=begin nd
Group: variable

variable: $self
    * FILEPATH_DATACONF => undef, # path of data's configuration file
    * sources  => [], # array of DataSource objects
=cut


####################################################################################################
#                                       CONSTRUCTOR METHODS                                        #
####################################################################################################

# Group: constructor

sub new {
    my $this = shift;

    my $class= ref($this) || $this;
    my $self = {
        FILEPATH_DATACONF => undef,
        sources  => []
    };

    bless($self, $class);

    TRACE;

    # init. class
    return undef if (! $self->_init(@_));

    # load. class
    return undef if (! $self->_load());

    return $self;
}


sub _init {
    my $self   = shift;
    my $params = shift;

    TRACE;
    
    return FALSE if (! defined $params);
    
    if (! exists($params->{filepath_conf}) || ! defined ($params->{filepath_conf})) {
        ERROR("key/value required to 'filepath_conf' !");
        return FALSE ;
    }
    if (! -f $params->{filepath_conf}) {
        ERROR (sprintf "Data's configuration file ('%s') doesn't exist !",$params->{filepath_conf});
        return FALSE;
    }
    $self->{FILEPATH_DATACONF} = $params->{filepath_conf};

    return TRUE;
}


sub _load {
    my $self   = shift;

    TRACE;

    my $propLoader = BE4::PropertiesLoader->new($self->{FILEPATH_DATACONF});

    if (! defined $propLoader) {
        ERROR("Can not load sources' properties !");
        return FALSE;
    }

    my $sourcesProperties = $propLoader->getAllProperties();

    if (! defined $sourcesProperties) {
        ERROR("All parameters properties of sources are empty !");
        return FALSE;
    }

    my $sources = $self->{sources};
    my $nbSources = 0;

    while( my ($level,$params) = each(%$sourcesProperties) ) {
        my $datasource = BE4::DataSource->new($level,$params);
        if (! defined $datasource) {
            ERROR(sprintf "Cannot create a DataSource object for the base level %s",$level);
            return FALSE;
        }
        push @{$sources}, $datasource;
        $nbSources++;
    }

    if ($nbSources == 0) {
        ERROR ("No source !");
        return FALSE;
    }

    return TRUE;
}


1;
__END__


=head1 NAME

    BE4::DataSource - Managing data sources

=head1 SYNOPSIS

    use BE4::DataSource;

    # DataSource object creation
    my $objDataSource = BE4::DataSource->new({
        path_conf => "/home/ign/images.source",
        type => "image"
    });

=head1 DESCRIPTION

    A DataSource object

        * FILEPATH_DATACONF
        * type : type of sources
        * sources : an hash of ImageSource or HarvestSource objects
        * SRS : SRS of the bottom extent (and GeoImage objects)
        * bottomExtent : an OGR geometry
        * bottomBbox : Bbox of bottomExtent [xmin,ymin,xmax,ymax]

    Possible values :

        type => ["harvest","image"]

=head1 FILE CONFIGURATION

    In the be4 configuration

        [ datasource ]
        type                = image
        filepath_conf       = /home/theo/TEST/BE4/SOURCE/images.source

    In the source configuration (.source)
        
        type 'image'

            [ global ]
            srs = IGNF:LAMB93

            [ 19 ]
            path_image = /home/theo/DONNEES/BDORTHO_PARIS-OUEST_2011_L93/DATA

            [ 14 ]
            path_image = /home/theo/DONNEES/BDORTHO_PARIS-EST_2011_L93/

        type 'harvest'

            [ global ]
            srs = IGNF:LAMB93
            box = 123,45,137,159
                    or
            box = /home/theo/TEST/BE4/SHAPE/Polygon.txt

            [ 19 ]
            wms_layer   = ORTHO_RAW_LAMB93_PARIS_OUEST
            wms_url     = http://localhost/wmts/rok4
            wms_version = 1.3.0
            wms_request = getMap
            wms_format  = image/tiff
            image_width = 2048
            image_height = 2048

            [ 14 ]
            wms_layer   = ORTHO_RAW_LAMB93_PARIS_EST
            wms_url     = http://localhost/wmts/rok4
            wms_version = 1.3.0
            wms_request = getMap
            wms_format  = image/tiff
            image_width = 4096
            image_height = 4096


=head1 LIMITATION & BUGS

    Metadata managing not yet implemented.

=head1 SEE ALSO

    BE4::HarvestSource
    BE4::ImageSource

=head1 AUTHOR

    Satabin Théo, E<lt>tsatabin@E<gt>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2011 by Satabin Théo

    This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself,
    either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.

=cut
