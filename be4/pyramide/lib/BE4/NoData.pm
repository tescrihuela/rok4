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

package BE4::NoData;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
use File::Spec::Link;
use File::Basename;
use File::Spec;
use File::Path;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{$EXPORT_TAGS{'all'}} );
our @EXPORT      = qw();

################################################################################
# version
our $VERSION = '0.0.1';

################################################################################
# constantes
use constant TRUE  => 1;
use constant FALSE => 0;
use constant CREATE_NODATA     => "createNodata";

################################################################################
# Global

################################################################################
# Preloaded methods go here.
BEGIN {}
INIT {}
END {}

################################################################################
# constructor
sub new {
  my $this = shift;

  my $class= ref($this) || $this;
  my $self = {
    pixel           => undef, # Pixel object
    value           => undef, # FFFFFF or -99999 by default !
    nowhite         => undef, # FALSE by default
  };

  bless($self, $class);
  
  TRACE;
  
  # init. class
  return undef if (! $self->_init(@_));
  
  return $self;
}

################################################################################
# privates init.
sub _init {
    my $self = shift;
    my $params = shift;

    TRACE;
    
    return FALSE if (! defined $params);
    
    # init. params
    # All attributes have to be present in parameters and defined, except 'value' which could be undefined

    if (! exists  $params->{nowhite} || ! defined  $params->{nowhite}) {
        ERROR ("Parameter 'nowhite' required !");
        return FALSE;
    }
    if (lc $params->{nowhite} eq 'true') {
        $self->{nowhite} = TRUE;
    }
    elsif (lc $params->{nowhite} eq 'false') {
        $self->{nowhite} = FALSE;
    } else {
        ERROR (sprintf "Parameter 'nowhite' is not valid (%s). Possible values are true or false !",$params->{nowhite});
        return FALSE;
    }

    if (! exists  $params->{pixel} || ! defined  $params->{pixel}) {
        ERROR ("Parameter 'pixel' required !");
        return FALSE;
    }
    $self->{pixel} = $params->{pixel};

    if (! exists  $params->{value}) {
        ERROR ("Parameter 'value' required !");
        return FALSE;
    }

#   for nodata value, it has to be coherent with bitspersample/sampleformat :
#       - 32/float -> an integer in decimal format (-99999 for a DTM for example)
#       - 8/uint -> a uint in hexadecimal format (FF for example. Just first two are used)
    if (! exists $params->{value} || ! defined ($params->{value})) {
        if (int($self->{pixel}->{bitspersample}) == 32 && $self->{pixel}->{sampleformat} eq 'float') {
            WARN ("Parameter 'nodata value' has not been set. The default value is -99999");
            $params->{value} = '-99999';
        } elsif (int($self->{pixel}->{bitspersample}) == 8 && $self->{pixel}->{sampleformat} eq 'uint') {
            WARN ("Parameter 'nodata value' has not been set. The default value is FFFFFF");
            $params->{value} = 'FF'x($self->{pixel}->{samplesperpixel});
        } else {
            ERROR ("sampleformat/bitspersample not supported !");
            return FALSE;
        }
    } else {
        if (int($self->{pixel}->{bitspersample}) == 32 && $self->{pixel}->{sampleformat} eq 'float') {
            if (!($params->{value} =~ m/^[-+]?(\d)+$/)) {
                ERROR (sprintf "Incorrect parameter nodata for a float32 pixel's format (%s) !",$params->{value});
                return FALSE;
            }
        } elsif (int($self->{pixel}->{bitspersample}) == 8 && $self->{pixel}->{sampleformat} eq 'uint') {
            if (!($params->{value}=~m/^[A-Fa-f0-9]{2,}$/)) {
                ERROR (sprintf "Incorrect parameter nodata for this int8 pixel's format (%s) !",$params->{value});
                return FALSE;
            }
        } else {
            ERROR ("sampleformat/bitspersample not supported !");
            return FALSE;
        }
    }
    
    $self->{value} = $params->{value};
    
    return TRUE;
}
################################################################################
# get /set
sub getValue {
  my $self = shift;
  return $self->{value};
}

################################################################################
# public method

# method: createNodata
#  create a nodata tile.
#---------------------------------------------------------------------------------------------------
sub createNodata {
    my $self = shift;
    my $nodataFilePath = shift;
    my $width = shift;
    my $height = shift;
    my $compression = shift;
    
    TRACE();
  
    # cas particulier de la commande createNodata :
    $compression = ($compression eq 'raw'?'none':$compression);
    
    my $cmd = sprintf ("%s -n %s",CREATE_NODATA, $self->{value});
    $cmd .= sprintf ( " -c %s", $compression);
    $cmd .= sprintf ( " -p %s", $self->{pixel}->{photometric});
    $cmd .= sprintf ( " -t %s %s",$width,$height);
    $cmd .= sprintf ( " -b %s", $self->{pixel}->{bitspersample});
    $cmd .= sprintf ( " -s %s", $self->{pixel}->{samplesperpixel});
    $cmd .= sprintf ( " -a %s", $self->{pixel}->{sampleformat});
    $cmd .= sprintf ( " %s", $nodataFilePath);

    my $nodatadir = dirname($nodataFilePath);

    if (! -d $nodatadir) {
        #create folders
        eval { mkpath([$nodatadir]); };
        if ($@) {
            ERROR(sprintf "Can not create the nodata directory '%s' : %s !", $nodatadir , $@);
            return FALSE;
        }
    }
    
    if (! system($cmd) == 0) {
        ERROR (sprintf "The command to create a nodata tile is incorrect : '%s'",$cmd);
        return FALSE;
    }

    return TRUE;
    
}


1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Bazonnais Jean Philippe, E<lt>jpbazonnais@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Bazonnais Jean Philippe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
