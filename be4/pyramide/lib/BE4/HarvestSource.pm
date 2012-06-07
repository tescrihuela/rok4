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

package BE4::HarvestSource;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use List::Util qw(min max);

use BE4::Harvesting;

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

BEGIN {}
INIT {}
END {}

################################################################################
=begin nd
Group: variable

variable: $self
    * harvesting => undef, # Harvesting object
    * image_width => 4096, # images size which will be harvested
    * image_height => 4096
=cut

####################################################################################################
#                                       CONSTRUCTOR METHODS                                        #
####################################################################################################

# Group: constructor

sub new {
  my $this = shift;

  my $class= ref($this) || $this;
  my $self = {
    harvesting => undef,
    image_width => 4096,
    image_height => 4096
  };

  bless($self, $class);
  
  TRACE;

  # init. class
  return undef if (! $self->_init(@_));
  
  return $self;
}


sub _init {
    my $self   = shift;
    my $harvestParams = shift;

    TRACE;
    
    return FALSE if (! defined $harvestParams);

    # parameters mandatoy !

    if (! exists($harvestParams->{image_width}) || ! defined ($harvestParams->{image_width})) {
        ERROR("key/value required to 'image_width' !");
        return FALSE ;
    }
    if (! exists($harvestParams->{image_height}) || ! defined ($harvestParams->{image_height})) {
        ERROR("key/value required to 'image_height' !");
        return FALSE ;
    }

    my $objHarvest = BE4::Harvesting->new({
        wms_layer => $harvestParams->{wms_layer},
        wms_url => $harvestParams->{wms_url},
        wms_version => $harvestParams->{wms_version},
        wms_request => $harvestParams->{wms_request},
        wms_format => $harvestParams->{wms_format}
    });
    if (! defined $objHarvest) {
        ERROR("Cannot create Harvesting object !");
        return FALSE ;
    }
    
    # init. params    
    $self->{harvesting} = $objHarvest;
    $self->{image_width} = $harvestParams->{image_width};
    $self->{image_height} = $harvestParams->{image_height};

    return TRUE;
}


1;
__END__


=head1 NAME

    BE4::HarvestSource

=head1 SYNOPSIS

    use BE4::HarvestSource;

    # HarvestSource object creation
    my $objHarvestSource = BE4::HarvestSource->new({
        wms_layer   => "ORTHO_RAW_LAMB93_PARIS_OUEST",
        wms_url     => "http://localhost/wmts/rok4",
        wms_version => "1.3.0",
        wms_request => "getMap",
        wms_format  => "image/tiff",
        image_width => 2048,
        image_height => 2048
    });

=head1 DESCRIPTION

    A HarvestSource object

        * harvesting : Harvesting object
        * image_width : max width of downloaded images
        * image_height : max height of downloaded images

=head2 EXPORT

    None by default.

=head1 SEE ALSO

    BE4::Harvesting

=head1 AUTHOR

    Satabin Théo, E<lt>tsatabin@E<gt>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2011 by Satabin Théo

    This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself,
    either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.

=cut
