package BE4::Pyramid;

use strict;
use warnings;

use Log::Log4perl qw(:easy);
# use Math::Base36 ':all';
use XML::Simple;
use XML::LibXML;

use File::Find::Node;
use File::Spec::Link;
use File::Basename;
use File::Spec;
use File::Path;

use Data::Dumper;

# My module
use BE4::Product;
use BE4::TileMatrixSet;
use BE4::Compression;
use BE4::Level;
use BE4::NoData;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{$EXPORT_TAGS{'all'}} );
our @EXPORT      = qw();

################################################################################
# version
our $VERSION = '0.0.3';

################################################################################
# constantes
use constant TRUE  => 1;
use constant FALSE => 0;

################################################################################
# Preloaded methods go here.
BEGIN {}
INIT {}
END {}

################################################################################
# properties :
#
#    [ pyramid ]
#
#    pyr_descpath      =
#    pyr_datapath      =
#    ; pyr_schema_path = 
#    ; pyr_schema_name =
#    
#    
#    pyr_name_old     =
#    pyr_name_new     =
#
#    ; eg section [ tilematrixset ]
#    tms_name     =  
#    tms_path     =
#    ; tms_schema_path = 
#    ; tms_schema_name =
#
#    image_width  = 
#    image_height =
#
#    compression  =
#    gamma        =
#
#    ; eg section [ tile ]
#    bitspersample       = 
#    sampleformat        = 
#    ; compressionscheme   = 
#    photometric         = 
#    samplesperpixel     =
#    interpolation       = 
#    
#    dir_depth    =
#    dir_image    = IMAGE
#    dir_metadata = METADATA
#
#    ; eg section [ nodata ]
#    path_nodata =
#    imagesize   =
#    color       =

################################################################################
# Global template Pyr

my $STRPYRTMPLT   = <<"TPYR";
<?xml version='1.0' encoding='US-ASCII'?>
<Pyramid>
    <tileMatrixSet>__TMSNAME__</tileMatrixSet>
    <format>__FORMATIMG__</format>
    <channels>__CHANNEL__</channels>
<!-- __LEVELS__ -->
</Pyramid>
TPYR

my $STRLEVELTMPLT = <<"TLEVEL";
    <level>
        <tileMatrix>__ID__</tileMatrix>
        <baseDir>__DIRIMG__</baseDir>
<!-- __MTD__ -->
        <tilesPerWidth>__TILEW__</tilesPerWidth>
        <tilesPerHeight>__TILEH__</tilesPerHeight>
        <pathDepth>__DEPTH__</pathDepth>
        <TMSLimits>
            <minTileRow>__MINROW__</minTileRow>
            <maxTileRow>__MAXROW__</maxTileRow>
            <minTileCol>__MINCOL__</minTileCol>
            <maxTileCol>__MAXCOL__</maxTileCol>
        </TMSLimits>
    </level>
<!-- __LEVELS__ -->
TLEVEL

my $STRLEVELTMPLTMORE = <<"TMTD";
            <metadata type='INT32_DB_LZW'>
		<baseDir>__DIRMTD__</baseDir>
		<format>__FORMATMTD__</format>
	    </metadata>
TMTD

################################################################################
# constructor
sub new {
  my $this = shift;

  my $class= ref($this) || $this;
  my $self = {
    #
    # WARNING !
    #
    # 2 options possible with parameters :
    #   - a new pyramid configuration
    #   - a existing pyramid configuration
    #
    # > in a HASH entry only (no ref) !
    #
    #
    # the choice is on the parameter 'pyr_name_old'
    #   1) if param is null, it's a new pyramid only !
    #   2) if param is not null, it's an existing pyramid !
    #
    
    # IN
    #  it's all possible parameters !
    pyramid   => { 
                    pyr_name_new => undef, # string name
                    pyr_name_old => undef, # string name
                    pyr_descpath => undef, # path
                    pyr_datapath => undef, # path
                    #
                    tms_name     => undef, # string name
                    tms_path     => undef, # path
                    #
                    compression  => undef, # string value ie raw by default !
                    gamma        => undef, # number ie 1 by default !
                    #
                    dir_depth    => undef, # number
                    dir_image    => undef, # dir name
                    dir_metadata => undef, # dir name
                    image_width  => undef, # number
                    image_height => undef, # number
                    #
                    bitspersample           => undef,# number
                    sampleformat            => undef,# number
                    # compressionscheme       => undef,# string value
                    photometric             => undef,# string value ie rgb by default !
                    samplesperpixel         => undef,# number
                    interpolation           => undef,# string value ie bicubique by default !
                    #
                    path_nodata     => undef, # path
                    imagesize       => undef, # number ie 4096 px by default !
                    color           => undef, # string value ie FFFFFF by default !
                 },
    # OUT
    tile       => undef,   # it's an object !
    tms        => undef,   # it's an object !
    nodata     => undef,   # it's an object !
    compression=> undef,   # it's an object !
    level      => [],      # it's a table of object level !
    cache_tile => [],      # ie tile to link  !
    cache_dir  => [],      # ie dir to search !
    #
    isnewpyramid => 1,     # new pyramid by default !
    
   };

  bless($self, $class);
  
  TRACE;
  
  # init. parameters 
  return undef if (! $self->_init(@_));
  
  # init. :
  # a new pyramid or from existing pyramid !
  return undef if (! $self->_load());
  
  return $self;
}

################################################################################
# privates init.

# TODO
#  - no test for path and type (string, number, ...) !

sub _init {
    my $self   = shift;
    my $params = shift;

    TRACE;

    if (! defined $params ) {
        ERROR ("paramters argument required (null) !");
        return FALSE;
    }
    
    # init. params .
    $self->{isnewpyramid} = 0 if (defined $params->{pyr_name_old});
    
    my $pyr = $self->{pyramid};
    
    if ($self->{isnewpyramid}) {
        # To a new pyramid, you must have to this parameters !
        #
        # you can choice this option by default !
        if (! exists($params->{compression})) {
            WARN ("key/value optional to 'compression' (value by default) !");
            $params->{compression} = 'raw';
        }
        $pyr->{compression}  = $params->{compression};
        #
        $pyr->{image_width}  = $params->{image_width}  || ( ERROR ("key/value required to 'image_width' !") && return FALSE );
        $pyr->{image_height} = $params->{image_height} || ( ERROR ("key/value required to 'image_height' !") && return FALSE );
        #
        $pyr->{tms_name}     = $params->{tms_name} || ( ERROR ("key/value required to 'tms_name' !") && return FALSE );
        #
        $pyr->{bitspersample}    = $params->{bitspersample}     || ( ERROR ("key/value required to 'bitspersample' !") && return FALSE );
        $pyr->{sampleformat}     = $params->{sampleformat}      || ( ERROR ("key/value required to 'sampleformat' !") && return FALSE );
        # $pyr->{compressionscheme}= $params->{compressionscheme} || ( ERROR ("key/value required to 'compressionscheme' !") && return FALSE );
        $pyr->{samplesperpixel}  = $params->{samplesperpixel}   || ( ERROR ("key/value required to 'samplesperpixel' !") && return FALSE ); 
       
    }
    else {
        # To an existing pyramid, you must have to this parameters !
        #
        $pyr->{pyr_name_old} = $params->{pyr_name_old} || ( ERROR ("key/value required to 'pyr_name_old' !") && return FALSE );
        #
        # this option can be determined !
        #
        if (! exists($params->{tms_name})) {
            WARN ("key/value optional to 'tms_name' (can be determined) !");
            $params->{tms_name} = undef;
        }
        #
        if (! exists($params->{compression})) {
            WARN ("key/value optional to 'compression' (can be determined) !");
            $params->{compression} = undef;
        }
    }
    #
    # All parameters are mandatory (or initializate by default) whatever the pyramid !
    # 
    $pyr->{pyr_name_new} = $params->{pyr_name_new} || ( ERROR ("key/value required to 'pyr_name_new' !") && return FALSE );
    $pyr->{pyr_descpath} = $params->{pyr_descpath} || ( ERROR ("key/value required to 'pyr_descpath' !") && return FALSE );
    $pyr->{pyr_datapath} = $params->{pyr_datapath} || ( ERROR ("key/value required to 'pyr_datapath' !") && return FALSE );
    #
    $pyr->{tms_path}     = $params->{tms_path}     || ( ERROR ("key/value required to 'tms_path' !") && return FALSE );
    #
    $pyr->{dir_depth}    = $params->{dir_depth}    || ( ERROR ("key/value required to 'dir_depth' !") && return FALSE );
    $pyr->{dir_image}    = $params->{dir_image}    || ( ERROR ("key/value required to 'dir_image' !") && return FALSE );
    #
    # this option is optional !
    #
    if (! exists($params->{dir_metadata})) {
        WARN ("key/value optional to 'dir_metadata' !");
        $params->{dir_metadata} = undef;
    }
    $pyr->{path_nodata}  = $params->{path_nodata} || ( ERROR ("key/value required to 'path_nodata' !") && return FALSE );
    # 
    # you can choice this option by default !
    #
    if (! exists($params->{imagesize})) {
        WARN ("key/value optional to 'imagesize' (value by default) !");
        $params->{imagesize} = '4096';
    }
    $pyr->{imagesize} = $params->{imagesize};
    # 
    if (! exists($params->{color})) {
        WARN ("key/value optional to 'color' (value by default) !");
        $params->{color} = 'FFFFFF';
    }
    $pyr->{color} = $params->{color};
    #
    if (! exists($params->{interpolation})) {
        WARN ("key/value optional to 'interpolation' (value by default) !");
        $params->{interpolation} = 'bicubique';
    }
    $pyr->{interpolation} = $params->{interpolation};
    #
    if (! exists($params->{photometric})) {
        WARN ("key/value optional to 'photometric' (value by default) !");
        $params->{photometric} = 'rgb';
    }
    $pyr->{photometric} = $params->{photometric};
    #
    if (! exists($params->{gamma})) {
        WARN ("key/value optional to 'gamma' (value by default) !");
        $params->{gamma} = 1;
    }
    $pyr->{gamma} = $params->{gamma};
    
    # TODO path !
    if (! -d $pyr->{path_nodata}) {}
    if (! -d $pyr->{pyr_descpath}) {}
    if (! -d $pyr->{tms_path}) {}
    if (! -d $pyr->{pyr_datapath}) {}
    
    return TRUE;
}

sub _load {
  my $self = shift;

  TRACE;
  
  if ($self->{isnewpyramid}) {
    
    # It's a new pyramid !
    
    # create Tile !
    my $objTile = BE4::Product->new({
        bitspersample    => $self->{pyramid}->{bitspersample},
        sampleformat     => $self->{pyramid}->{sampleformat},
        # compressionscheme=> $self->{pyramid}->{compressionscheme},
        photometric      => $self->{pyramid}->{photometric},
        samplesperpixel  => $self->{pyramid}->{samplesperpixel},
        interpolation    => $self->{pyramid}->{interpolation},
    });
    
    if (! defined $objTile) {
      ERROR ("Can not load tile !");
      return FALSE;
    }
    
    $self->{tile} = $objTile;
    DEBUG (sprintf "TILE = %s", Dumper($objTile));
    
    # create Compress !
    my $objCompress = BE4::Compression->new($self->{pyramid}->{compression});
    
    if (! defined $objCompress) {
      ERROR ("Can not load compression !");
      return FALSE;
    }
    
    $self->{compression} = $objCompress;
    DEBUG (sprintf "COMPRESSION = %s", Dumper($objCompress));
    
    # create TileMatrixSet !
    my $objTMS = BE4::TileMatrixSet->new(File::Spec->catfile($self->{pyramid}->{tms_path},
                                                             $self->{pyramid}->{tms_name}));
    
    if (! defined $objTMS) {
      ERROR ("Can not load TMS !");
      return FALSE;
    }
    
    $self->{tms} = $objTMS;
    DEBUG (sprintf "TMS = %s", Dumper($objTMS));
    
    # init. method has checked all parameters,
    # so we can only create all level...
    
    return FALSE if (! $self->_fillToPyramid());
  }
  else 
  {
    # a new pyramid from existing pyramid !
    #
    # init. process hasn't checked all parameters,
    # so, we must read file pyramid to initialyze them...
    
    return FALSE if (! $self->_fillFromPyramid());
  }

  # create NoData !
  my $objNodata = BE4::NoData->new({
            path_nodata      => $self->{pyramid}->{path_nodata},
            bitspersample    => $self->getTile()->getBitsPerSample(),
            sampleformat     => $self->getTile()->getSampleFormat(),
            photometric      => $self->getTile()->getPhotometric(),
            samplesperpixel  => $self->getTile()->getSamplesPerPixel(),
            imagesize        => $self->{pyramid}->{imagesize}, 
            color            => $self->{pyramid}->{color}
  });
  
  if (! defined $objNodata) {
    ERROR ("Can not load NoData !");
    return FALSE;
  }
    
  $self->{nodata} = $objNodata;
  DEBUG (sprintf "NODATA = %s", Dumper($objNodata));
   
  return TRUE;
  
}
sub _fillToPyramid { 
  my $self  = shift;

  TRACE;
  
  # get tms object
  my $objTMS = $self->getTileMatrixSet();
  
  if (! defined $objTMS) {
    ERROR("Object TMS not defined !");
    return FALSE;
  }
  
  # load all level
  my $i = ($objTMS->getFirstTileMatrix())->getID();
  while(defined (my $objTm = $objTMS->getNextTileMatrix($i))) {
    
    my $tileperwidth     = $self->getTilePerWidth(); 
    my $tileperheight    = $self->getTilePerHeight();
    
    # base dir image
    my $baseimage = File::Spec->catdir($self->getPyrDataPath(),  # all directories structure of pyramid ! 
                                  $self->getPyrName(),
                                  $self->getDirImage(),
                                  $objTm->getID()               # FIXME : level = id !
                                  );
    
    # TODO : metadata
    #   compression, type ...
    my $basemetadata = File::Spec->catdir($self->getPyrDataPath(),  # all directories structure of pyramid ! 
                                  $self->getPyrName(),
                                  $self->getDirMetadata(),
                                  $objTm->getID()                  # FIXME : level = id !
                                  );
    
    # FIXME :
    #   compute tms limit in row/col from TMS ?
    
    # params to level
    my $params = {
            id                => $objTm->getID(),
            dir_image         => File::Spec->abs2rel($baseimage, $self->getPyrDescPath()), # FIXME rel with the pyr path !
            compress_image    => $self->getCompression()->getCode(), # ie raw => TIFF_INT8 !
            dir_metadata      => undef,           # TODO,
            compress_metadata => undef,           # TODO  : raw  => TIFF_INT8,
            type_metadata     => "INT32_DB_LZW",  # FIXME : type => INT32_DB_LZW, 
            bitspersample     => $self->getTile()->getBitsPerSample(),
            samplesperpixel   => $self->getTile()->getSamplesPerPixel(),
            size              => [ $tileperwidth, $tileperheight],
            dir_depth         => $self->getDirDepth(),
            limit             => [1, 1000000, 1, 1000000] # FIXME : can be computed or fix ?
    };
    my $objLevel = BE4::Level->new($params);
    
    if(! defined  $objLevel) {
      ERROR (sprintf "Can not create the level '%s' !", $objTm->getID());
      return FALSE;
    }
    push @{$self->{level}}, $objLevel;
    # push dir to create
    push @{$self->{cache_dir}}, File::Spec->abs2rel($baseimage, $self->getPyrDataPath());
    $i++;
  }
  
  if (! scalar (@{$self->{level}})) {
    ERROR ("No level loaded !");
    return FALSE;
  }
  
  return TRUE;
}
sub _fillFromPyramid {
  my $self  = shift;
  
  TRACE;
  
  my $filepyramid = $self->getPyrFileOld();
  
  if (! $self->readConfPyramid($filepyramid)) {
    ERROR (sprintf "Can not read the XML file Pyramid : %s !", $filepyramid);
    return FALSE;
  }
  
  my $cachepyramid = File::Spec->catdir($self->getPyrDataPath(),
                                        $self->getPyrNameOld());
  
  if (! $self->readCachePyramid($cachepyramid)) {
    ERROR (sprintf "Can not read the Directory Cache Pyramid : %s !", $cachepyramid);
    return FALSE;
  }
  
  return TRUE;
}
################################################################################
# public method serialization
#  Manipulate the Configuration File Pyramid /* in/out */

sub writeConfPyramid {
  my $self    = shift;
  my $pyrfile = shift; # Can be null !
  
  TRACE;
  
  # parsing template
  my $parser = XML::LibXML->new();
  
  my $doctpl = eval { $parser->parse_string($STRPYRTMPLT); };
  if (!defined($doctpl) || $@) {
    ERROR(sprintf "Can not parse template file of pyramid : %s !", $@);
    return FALSE;
  }
  my $strpyrtmplt = $doctpl->toString(0);
  
  #
  my $tmsname  = $self->getTmsName();
  $strpyrtmplt =~ s/__TMSNAME__/$tmsname/;
  #
  my $formatimg = $self->getCompression()->getCode(); # ie TIFF_INT8 !
  $strpyrtmplt  =~ s/__FORMATIMG__/$formatimg/;
  #  
  my $channel  = $self->getTile()->getSamplesPerPixel();
  $strpyrtmplt =~ s/__CHANNEL__/$channel/;
  
  my @levels = $self->getLevels();
  foreach my $objLevel (@levels){
    
    # image
    $strpyrtmplt =~ s/<!-- __LEVELS__ -->\n/$STRLEVELTMPLT/;
    
    my $id       = $objLevel->{id};
    $strpyrtmplt =~ s/__ID__/$id/;
    
    my $dirimg   = $objLevel->{dir_image};
    $strpyrtmplt =~ s/__DIRIMG__/$dirimg/;
    
    # my $formatimg = $objLevel->{compress_image}; # ie TIFF_INT8 !
    # $strpyrtmplt  =~ s/__FORMATIMG__/$formatimg/;
    #
    # my $channel  = $objLevel->{samplesperpixel};
    # $strpyrtmplt =~ s/__CHANNEL__/$channel/;
    
    my $tilew    = $objLevel->{size}->[0];
    $strpyrtmplt =~ s/__TILEW__/$tilew/;
    my $tileh    = $objLevel->{size}->[1];
    $strpyrtmplt =~ s/__TILEH__/$tileh/;
    
    my $depth    =  $objLevel->{dir_depth};
    $strpyrtmplt =~ s/__DEPTH__/$depth/;
    
    my $minrow   =  $objLevel->{limit}->[0];
    $strpyrtmplt =~ s/__MINROW__//;
    my $maxrow   =  $objLevel->{limit}->[1];
    $strpyrtmplt =~ s/__MAXROW__/$maxrow/;
    my $mincol   =  $objLevel->{limit}->[2];
    $strpyrtmplt =~ s/__MINCOL__/$mincol/;
    my $maxcol   =  $objLevel->{limit}->[3];
    $strpyrtmplt =~ s/__MAXCOL__/$maxcol/;
    
    # metadata
    if (defined $objLevel->{dir_metadata}) {
        
        $strpyrtmplt =~ s/<!-- __MTD__ -->/$STRLEVELTMPLTMORE/;
        
        my $dirmtd   = $objLevel->{dir_metadata};
        $strpyrtmplt =~ s/__DIRMTD__/$dirmtd/;
        
        my $formatmtd = $objLevel->{compress_metadata};
        $strpyrtmplt  =~ s/__FORMATMTD__/$formatmtd/;
    }
    $strpyrtmplt =~ s/<!-- __MTD__ -->\n//;
  }
  #
  $strpyrtmplt =~ s/<!-- __LEVELS__ -->\n//;
  $strpyrtmplt =~ s/^$//g;
  $strpyrtmplt =~ s/^\n$//g;
  #
  
  # TODO check the new template !
  
  # if null, by default, take the new pyramid file !
  $pyrfile = $self->getPyrFile() if (! defined $pyrfile);
  
  #
  my $filepyramid = File::Spec->catfile($self->getPyrDescPath(), 
                                        $pyrfile);
  
  if (-f $filepyramid) {
    ERROR(sprintf "File Pyramid ('%s') exist, can not overwrite it ! ", $pyrfile);
    return FALSE;
  }
  #
  my $PYRAMID;
  
  if (! open $PYRAMID, ">", $filepyramid) {
    ERROR("");
    return FALSE;
  }
  #
  printf $PYRAMID "%s", $strpyrtmplt;
  #
  close $PYRAMID;
}
sub readConfPyramid {
  my $self    = shift;
  my $pyrfile = shift; # Can be null !
    
  TRACE;
  
  # if null, by default, take the old pyramid file !
  $pyrfile = $self->getPyrFileOld() if (! defined $pyrfile);
  
  my $filepyramid = File::Spec->catfile($self->getPyrDescPath(), $pyrfile);
  
  if (! -f $filepyramid) {
    ERROR (sprintf "Can not find the XML file Pyramid : %s !", $filepyramid);
    return FALSE;
  }
  
  # read xml pyramid
  my $xmltms  = new XML::Simple(KeepRoot => 0,
                                SuppressEmpty => 1,
                                ContentKey => '-content');
  my $xmltree = eval { $xmltms->XMLin($filepyramid); };
  
  if ($@) {
    ERROR (sprintf "Can not read the XML file Pyramid : %s !", $@);
    return FALSE;
  }
  
  # read tag value of tileMatrixSet, format and channel
  if (! exists ($xmltree->{tileMatrixSet}) || ! defined ($xmltree->{tileMatrixSet})) {
    ERROR (sprintf "Can not determine parameter 'tileMatrixSet' in the XML file Pyramid !");
    return FALSE;
  }
  
  if (! exists ($xmltree->{format}) || ! defined ($xmltree->{format})) {
    ERROR (sprintf "Can not determine parameter 'format' in the XML file Pyramid !");
    return FALSE;
  }
  
  if (! exists ($xmltree->{channels}) || ! defined ($xmltree->{channels})) {
    ERROR (sprintf "Can not determine parameter 'channels' in the XML file Pyramid !");
    return FALSE;
  }
  
  # create a object tileMatrixSet
  my $tmsname = $self->getTmsName();
  if (! defined $tmsname) {
    WARN ("Null parameter for the name of TMS, so extracting from file pyramid !");
    $tmsname = $xmltree->{tileMatrixSet};
  }

  if ($tmsname ne $xmltree->{tileMatrixSet}) {
    WARN ("Selecting the name of TMS in the file of the pyramid !");
    $tmsname = $xmltree->{tileMatrixSet};
  }
  
  # FIXME : no extension in xml pyramid file ?
  my $tmsfile = join(".", $tmsname, "tms"); 
  
  my $objTMS = BE4::TileMatrixSet->new(File::Spec->catfile($self->getTmsPath(), $tmsfile));
  
  if (! defined $objTMS) {
    ERROR ("Can not create object TileMatrixSet !");
    return FALSE;
  }
  
  # save it if doesn't exist !
  if (! defined ($self->getTileMatrixSet())) {
    $self->{tms} = $objTMS;
  }
    
  # fill parameters if not... !
  $self->{pyramid}->{tms_name} = $self->getTileMatrixSet()->getFile();
  $self->{pyramid}->{tms_path} = $self->getTileMatrixSet()->getPath();
  
  # create tile and compression objects
  my $format = $xmltree->{format};
  # ie TIFF, compression, sampleformat, bitspersample !
  # return compression = raw, jpg or png !
  my ($formatimg, $compression, $sampleformat, $bitspersample) = BE4::Compression->decodeCompression($format);
  
  my $samplesperpixel = $xmltree->{channels};
  
  # create tile
  my $tile = {
        bitspersample    => $bitspersample,
        sampleformat     => $sampleformat,
        # compressionscheme=> 'none', # FIXME always none !
        photometric      => $self->getPhotometric(),
        samplesperpixel  => $samplesperpixel,
        interpolation    => $self->getInterpolation(),
  };
   
  my $objTile = BE4::Product->new($tile);
    
  if (! defined $objTile) {
    ERROR ("Can not create the Tile format !");
    return FALSE;
  }

  # save it if doesn't exist !
  if (! defined ($self->getTile())) {
    $self->{tile} = $objTile;
  }
  
  # create compression
  if (! defined ($self->getCompression())) {
    
    my $type = undef;
    
    # priority in this choice ...
    $type = $compression if (defined $compression);
    $type = $self->{pyramid}->{compression} if (defined $self->{pyramid}->{compression});
    
    my $objCompress = BE4::Compression->new($type);

    if (! defined $objCompress) {
        ERROR ("Can not load compression !");
        return FALSE;
    }

    $self->{compression} = $objCompress;
  }
  
  # check compression mode 
  if ($self->getCompression()->getCode() ne $format) {
    ERROR (sprintf "The mode compression is differnt between configuration and pyramid file !", $format, $self->getCompression()->getCode());
    return FALSE;
  }
    
  # load pyramid level
  foreach my $v (@{$xmltree->{level}}) {
    
    #
    my $baseimage = File::Spec->catdir($self->getPyrDataPath(),  # all directories structure of pyramid ! 
                                  $self->getPyrName(),
                                  $self->getDirImage(),
                                  $v->{tileMatrix}           # FIXME : level = id !
                                  );
    #
    my $objLevel = BE4::Level->new({
            id                => $v->{tileMatrix},
            dir_image         => File::Spec->abs2rel($baseimage, $self->getPyrDescPath()), # FIXME rel with pyr file ?
            compress_image    => $format, # ie TIFF_INT8 !
            dir_metadata      => undef,   # TODO !
            compress_metadata => undef,   # TODO !
            type_metadata     => undef,   # TODO !
            bitspersample     => $bitspersample,
            samplesperpixel   => $samplesperpixel,
            size              => [
                                  $v->{tilesPerWidth},
                                  $v->{tilesPerHeight}
                                  ],
            dir_depth         => $v->{pathDepth},
            limit             => [
                                  $v->{TMSLimits}->{minTileRow},
                                  $v->{TMSLimits}->{maxTileRow},
                                  $v->{TMSLimits}->{minTileCol},
                                  $v->{TMSLimits}->{maxTileCol}
                                  ]
                          });
    
    if (! defined $objLevel) {
        WARN(sprintf "Can not load the pyramid level : '%s'", $v->{tileMatrix});
        next;
    }
    
    push @{$self->{level}}, $objLevel;
    
    # fill parameters if not ... !
    $self->{pyramid}->{image_width}  = $v->{tilesPerWidth};
    $self->{pyramid}->{image_height} = $v->{tilesPerHeight};
  }
  
  #
  if (scalar @{$self->{level}} != scalar @{$xmltree->{level}}) {
    WARN (sprintf "Be careful, the level pyramid in not complete (%s != %s) !",
          scalar @{$self->{level}},
          scalar @{$xmltree->{level}});
  }
  #
  if (! scalar @{$self->{level}}) {
    ERROR ("List of Level Pyramid is empty !");
    return FALSE;
  }
  
  # clean
  $xmltree = undef;
  $xmltms  = undef;
  
  return TRUE;
}

#############################################################################
# public method serialization (on disk)
#  Manipulate the Directory Structure Cache (DSC) /* in/out */
sub writeCachePyramid {
  my $self = shift;
  
  TRACE;
  
  #
  # Params useful to create a cache directory empty or not 
  #
  # pyr_datapath : path of all pyramid
  # pyr_name_new : new pyramid name
  # pyr_name_old :
  # dir_image    : 
  # cache_dir    : old or new
  # cache_tile   : old
  
  my $newpyrname = $self->getPyrName();
  my $oldpyrname = $self->getPyrNameOld();
  my $dirimage   = $self->getDirImage();
  my $dirmetadata= undef; # TODO ?
  
  # substring function 
  my $substring;
  $substring = sub {
    my $expr = shift;
    $_       = $expr;
    
    my $regex = undef;
    
    if ($expr !~ /$dirimage/) {
        $regex = "s/".$oldpyrname."/".$newpyrname.'\/'.$dirimage."/";
    }
    else {
        $regex = "s/".$oldpyrname."/".$newpyrname."/";
    }

    eval ($regex);
    if ($@) {
      ERROR(sprintf "REGEXE", $regex, $@);
      return FALSE;
    }
    
    return $_;
  };
  # create new cache directory
  my @newdirs;
  my @olddirs = @{$self->{cache_dir}};
  
  if ($self->isNewPyramid()) {
    @newdirs = @{$self->{cache_dir}};
  }
  else {
    @newdirs = map ({ &$substring($_) } @{$self->{cache_dir}}); # list cache modified !
  }
  
  if (! scalar @newdirs) {
    ERROR("Listing of new cache directory is empty !");
    return FALSE;
  }
  
  foreach my $dir (@newdirs) {
    
    my $absdir = File::Spec->catdir($self->getPyrDataPath(), $dir);
    
    DEBUG($absdir);
    
    eval { mkpath([$absdir],0,0751); };
    if ($@) {
      ERROR(sprintf "Can not create the cache directory '%s' : %s !", $dir , $@);
      return FALSE;
    }
    
  }
  # search and create link for only new cache tile
  if (! $self->isNewPyramid()) {
    
    my @oldtiles = @{$self->{cache_tile}};
    my @newtiles = map ({ &$substring($_) } @{$self->{cache_tile}}); # list cache modified !
    my $ntile    = scalar(@oldtiles)-1;
    
    if (! scalar @oldtiles) {
      WARN("Listing of old cache tile is empty !");
      # return FALSE;
    }
    
    if (! scalar @newtiles) {
      WARN("Listing of new cache tile is empty !");
      # return FALSE;
    }
    
    foreach my $i (0..$ntile) {
      
      my $new_absfile = File::Spec->catfile($self->getPyrDataPath(), $newtiles[$i]);
      my $old_absfile = File::Spec->catfile($self->getPyrDataPath(), $oldtiles[$i]);
      
      if (! -d dirname($new_absfile)) {
        ERROR(sprintf "The directory cache '%s' doesn't exist !", dirname($new_absfile));
        return FALSE;
      }
      
      if (! -e $old_absfile) {
        ERROR(sprintf "The tile '%s' doesn't exist in '%s' !", basename($old_absfile), dirname($old_absfile));
        return FALSE;  
      }
      
      my $follow_file = undef;
      
      if (-f $old_absfile) {
        $follow_file = File::Spec->abs2rel($old_absfile, dirname($new_absfile));
      }
      elsif (-l $old_absfile) {
        $follow_file = File::Spec->abs2rel(File::Spec::Link->resolve($old_absfile), dirname($new_absfile));
      }
      else {
        ERROR(sprintf "The tile '%s' is not a file or a link in '%s' !", basename($old_absfile), dirname($old_absfile));
        return FALSE;  
      }
      
      if (! defined $follow_file) {
        ERROR (sprintf "The link '%s' can not be resolved in '%s' ?", basename($old_absfile), dirname($old_absfile));
        return FALSE;
      }
      
      my $result = eval { symlink ($follow_file, $new_absfile); };
      if (! $result) {
        ERROR (sprintf "The tile '%s' can not be linked in '%s' (%s) ?", basename($follow_file), dirname($new_absfile), $@);
        return FALSE;
      }
    }
  }
  
  return TRUE;
  
}
sub readCachePyramid {
  my $self     = shift;
  my $cachedir = shift;
  
  TRACE;
  
    # fill list following in memory :
    #
    #  cache_dir
    #  cache_tile
    #
    # This list serve to create directory cache (with tile linked)
  
  my @refcachedir;
  my @refcachetile;
  my $pyr_datapath = $self->getPyrDataPath();
   
  # anonymous fonction
  my $searchItem;
  $searchItem = sub {
      my $fl   = shift;
      
      if ($fl->type eq 'd') {
        TRACE(sprintf "DIR:%s\n",$fl->path);
        push @refcachedir, File::Spec->abs2rel($fl->path, $pyr_datapath);
      }
      if ($fl->type eq 'f') {
        TRACE(sprintf "FIL:%s\n",$fl->path);
        push @refcachetile, File::Spec->abs2rel($fl->path, $pyr_datapath);
      }
      if ($fl->type eq 'l') {
        TRACE(sprintf "LIK:%s\n",$fl->path);
        push @refcachetile, File::Spec->abs2rel($fl->path, $pyr_datapath);        
      } 
      TRACE(sprintf "[NAME:%s]\n",$fl->name);
  };
  
  # Node
  my $searchitem = File::Find::Node->new(File::Spec->rel2abs($cachedir));

  # follow link
  $searchitem->follow(0); 

  # search
  $searchitem->process(\&$searchItem);
  $searchitem->filter(sub{sort @_});
  $searchitem->find;
  
  # Info, cache file of old cache !
  if (! scalar @refcachetile) {
    WARN("No tiles found in directory cache ?");
  }
  # Info, cache dir of old cache !
  if (! scalar @refcachedir){
    ERROR("No directory found in directoty cache ?");
    return FALSE;
  }
  
  $self->{cache_dir} = \@refcachedir;
  $self->{cache_tile}= \@refcachetile;
  
  return TRUE;
}

################################################################################
# get/set
#  return the params values
sub getPyrFile {
  my $self = shift;

  my $file = $self->{pyramid}->{pyr_name_new};

  return undef if (! defined $file);
  
  if ($file !~ m/\.(pyr|PYR)$/) {
    $file = join('.', $file, "pyr");
  }
  return $file;
}


sub getPyrFileOld {
  my $self = shift;

  my $file = $self->{pyramid}->{pyr_name_old};
  return undef if (! defined $file);
  if ($file !~ m/\.(pyr|PYR)$/) {
    $file = join('.', $file, "pyr");
  }
  return $file;

}
sub getPyrNameOld {
  my $self = shift;
  
  my $name = $self->{pyramid}->{pyr_name_old};
  return undef if (! defined $name);
  $name =~ s/\.(pyr|PYR)$//;
  return $name;
}
sub getPyrDescPath {
  my $self = shift;

  return $self->{pyramid}->{pyr_descpath};
}
sub getPyrDataPath {
  my $self = shift;
  
  return $self->{pyramid}->{pyr_datapath};
}
sub getPyrName {
  my $self = shift;
  
  my $name = $self->{pyramid}->{pyr_name_new};
  return undef if (! defined $name);
  $name =~ s/\.(pyr|PYR)$//;
  return $name;
}
# 
sub getTmsName {
  my $self   = shift;
  
  my $name = $self->{pyramid}->{tms_name};
  return undef if (! defined $name);
  $name =~ s/\.(tms|TMS)$//;
  return $name;
}

sub getTmsFile {
  my $self   = shift;
  
  my $file = $self->{pyramid}->{tms_name};
  return undef if (! defined $file);
  if ($file =! m/\.(tms|TMS)$/) {
    $file = join('.', $file, "tms");
  }
  return $file;

}
sub getTmsPath {
  my $self   = shift;
  
  return $self->{pyramid}->{tms_path};
}
# 
sub getDirImage {
  my $self = shift;
  
  return $self->{pyramid}->{dir_image};
}
sub getDirMetadata {
  my $self = shift;
  
  return $self->{pyramid}->{dir_metadata};
}
sub getDirDepth {
  my $self = shift;
  
  return $self->{pyramid}->{dir_depth};
}
#
sub getInterpolation {
  my $self = shift;
  
  return $self->{pyramid}->{interpolation};
}
sub getPhotometric {
  my $self = shift;
  
  return $self->{pyramid}->{photometric};
}
sub getGamma {
  my $self = shift;
  
  return $self->{pyramid}->{gamma};
}
#
################################################################################
# get/set
#  return the objects values
sub getNoData {
  my $self = shift;
  return $self->{nodata};
}
#  
sub getCompression {
  my $self = shift;
  return $self->{compression}; # ie raw, jpg or png !
}
# 
sub getTile {
   my $self = shift;
   return $self->{tile};
}
sub setTile {
  my $self = shift;
  my $tile = shift;
  
  $self->{tile} = $tile;
}
# 
sub getTileMatrixSet {
  my $self = shift;
  
  return $self->{tms};
}
sub setTileMatrixSet {
  my $self = shift;
  my $tms  = shift;
  
  $self->{tms} = $tms;
}

################################################################################
# get/set
#  return the list of objects values
sub getLevels {
  my $self = shift;
  return @{$self->{level}};
}
################################################################################
# privates method (low level)
#  Manipulate the Directory Structure Cache (DSC)

sub _IDXtoX {
  my $self  = shift;
  my $level = shift;
  my $idx   = shift; # x index !
  
  #Res  : 2 m  (determined by level)
  #Xmin : 933888.00
  #Ymax : 6537216.00
  #Size : 8192 m (imagesize = 4096*4096)
  #Level: 3
  #Index X = 933888/8192 = 114
  #Index Y = (16777216-6537216)/8192 = 1250
  
  my $tm  = $self->getTileMatrixSet()->getTileMatrix($level);
  
  my $xo  = $tm->getTopLeftCornerX();
  my $rx  = $tm->getResolution();
  my $sx  = $self->getCacheImageWith();
  
  my $x = ($idx * $rx * $sx) + $xo ;

  return $x;    
}
sub _IDXtoY {
  my $self  = shift;
  my $level = shift;
  my $idx   = shift; # y index !
  
  my $tm  = $self->getTileMatrixSet()->getTileMatrix($level);
  
  my $yo  = $tm->getTopLeftCornerY();
  my $ry  = $tm->getResolution();
  my $sy  = $self->getCacheImageHeight();
  
  my $y = $yo - ($idx * $ry * $sy);
  
  return $y;
}
sub _XtoIDX {
  my $self  = shift;
  my $level = shift;
  my $x     = shift; # x meters !
  
  my $idx = undef;
  #Res  : 2 m  (determined by level)
  #Xmin : 933888.00
  #Ymax : 6537216.00
  #Size : 8192 m (imagesize = 4096*4096)
  #Level: 3
  #Index X = 933888/8192 = 114
  #Index Y = (16777216-6537216)/8192 = 1250
  
  my $tm  = $self->getTileMatrixSet()->getTileMatrix($level);
  
  my $xo  = $tm->getTopLeftCornerX();
  my $rx  = $tm->getResolution();
  my $sx  = $self->getCacheImageWith();
  
  $idx = int(($x - $xo) / ($rx * $sx)) ;

  return $idx;
}
sub _YtoIDX {
  my $self  = shift;
  my $level = shift;
  my $y     = shift; # y meters !
  
  my $idx = undef;
  
  my $tm  = $self->getTileMatrixSet()->getTileMatrix($level);
  
  my $yo  = $tm->getTopLeftCornerY();
  my $ry  = $tm->getResolution();
  my $sy  = $self->getCacheImageHeight();
  
  $idx = int(($yo - $y) / ($ry * $sy)) ;
  
  return $idx;
}
sub _encodeIDXtoB36 {
  my $self  = shift;
  my $number= shift; # idx !
  
  my $padlength = $self->getDirDepth() + 1;
  
  my $b36 = "";
  $b36 = "000" if $number == 0;
  
  while ( $number ) {
    my $v = $number % 36;
    if($v <= 9) {
        $b36 .= $v;
    } else {
        $b36 .= chr(55 + $v); # Assume that 'A' is 65
    }
    $number = int $number / 36;
  }
  # my $b36       = encode_base36($number);
  
  # fill with 0 !
  $b36 = "0"x($padlength - length $b36).reverse($b36);

  INFO ($b36);

  return $b36;
}
sub _encodeB36toIDX {
  my $self = shift;
  my $b36  = shift; # idx in base 36 !
  
  my $padlength = $self->getDirDepth() + 1;
  
  my $number = 0;
  my $i = 0;
  foreach(split //, reverse uc $b36) {
    $_ = ord($_) - 55 unless /\d/; # Assume that 'A' is 65
    $number += $_ * (36 ** $i++);
  }
  
  INFO ("0"x($padlength - length $number).$number);
  
  # fill with 0 !
  return "0"x($padlength - length $number).$number;
  # return decode_base36($b36,$padlength);
}

################################################################################
# public method (up level)
#  Manipulate the Directory Structure Cache (DSC)

#sub createCache {}
#sub duplicateCache {}
#sub createCacheByLevel {}
#sub deleteCacheByLevel {}
#sub duplicateCacheByLevel {}

################################################################################
# public method
#  TileImage from Cache (TIC)
#
# FIXME ?
#  difference entre le parametre imagesize et TilePerWidth*TileWidth ?
#
sub getImageSize {
  my $self = shift;
  # size of cache image in pixel !
  return $self->{pyramid}->{imagesize} ;
}
sub getCacheImageSize {
  my $self = shift;
  # size of cache image in pixel !
  return ($self->getCacheImageWith(), $self->getCacheImageHeight());
}
sub getCacheImageWith {
  my $self = shift;
  # size of cache image in pixel !
  return $self->getTilePerWidth() * $self->getTileMatrixSet()->getTileWidth();
}
sub getCacheImageHeight {
  my $self = shift;
  # size of cache image in pixel !
  return $self->getTilePerHeight() * $self->getTileMatrixSet()->getTileHeight();
}
#
sub getTilePerWidth {
  my $self = shift;

  return $self->{pyramid}->{image_width};
}
sub getTilePerHeight {
  my $self = shift;
  
  return $self->{pyramid}->{image_height};
}

# retourne le chemin du fichier de la dalle à partir de la racine de l'arbo de
# la pyramide.
# ex: IMAGES/3e/42/01.tif
# ex: METADATA/3e/42/01.tif
sub getCacheNameOfImage {
  my $self  = shift;
  my $level = shift;
  my $x     = shift; # X idx !
  my $y     = shift; # Y idx !
  my $type  = shift;
  
  my $typeDir;
  if ($type eq "data"){
    $typeDir=$self->getDirImage();
  } elsif ($type eq "metadata"){
    $typeDir=$self->getDirMetadata();;
  }
  
  #my $xb36 = $self->_encodeIDXtoB36($self->_getIDXX($level, $x));
  #my $yb36 = $self->_encodeIDXtoB36($self->_getIDXY($level,$y));
  
  my $xb36 = $self->_encodeIDXtoB36($x);
  my $yb36 = $self->_encodeIDXtoB36($y);

  my @xcut = split (//, $xb36);
  my @ycut = split (//, $yb36);
  
  if (scalar(@xcut) != scalar(@ycut)) {
    ERROR("xb36 and yb36 are not the same size ?");
    return undef;
  }
  
  my $padlength = $self->getDirDepth() + 1;
  my $size      = scalar(@xcut);
  my $pos       = $size;
  my @l;
  
  if ($padlength>$size) {
    ERROR("xb36 and yb36 are more greater than the dir depth parameter ?");
    return undef;
  }
  
  for(my $i=0; $i<$padlength;$i++) {
    $pos--;
    push @l, $ycut[$pos];
    push @l, $xcut[$pos];
    push @l, '/';
  }
  
  pop @l;
  
  if ($size>$padlength) {
    while ($pos) {
        $pos--;
        push @l, $ycut[$pos];
        push @l, $xcut[$pos];
    }
  }
  
  my $imagePath     = scalar reverse(@l);
  my $imagePathName = join('.', $imagePath, 'tif');
  
  return File::Spec->catfile($typeDir, $level, $imagePathName); 
}

# retourne le chemin absolu du fichier de la dalle en paramètre.
# ex: /mnt/data/PYRAMIDS/ORTHO/IMAGES/34/31/0a.tif
sub getCachePathOfImage {
  my $self  = shift;
  my $level = shift;
  my $x     = shift;
  my $y     = shift;
  my $type  = shift;
  
  my $imageName = $self->getCacheNameOfImage($level, $x, $y, $type);
  
  return File::Spec->catfile($self->getPyrDataPath(), $self->getPyrName(), $imageName); 
}

# ref to getCacheNameOfImage !
sub getCacheImageName {
  my $self  = shift;
  my $level = shift;
  my $x     = shift;
  my $y     = shift;
  my $type  = shift;

  return $self->getCacheNameOfImage($level, $x, $y, $type);
  
}
# ref to getCachePathOfImage !
sub getCacheImagePath {
  my $self  = shift;
  my $level = shift;
  my $x     = shift;
  my $y     = shift;
  my $type  = shift;

  return  $self->getCachePathOfImage($level, $x, $y, $type);
}
################################################################################
# public method
#  
sub isNewPyramid {
  my $self = shift;
  return $self->{isnewpyramid};
}
################################################################################
# public method
#  TileImage of Work (TIW)

# No manipulation of TIW by Class Pyramid !

################################################################################
# public method
#  Manipulate the Level Pyramid

#sub getBottomLevel {}
#sub getTopLevel {}

################################################################################
# public method
#  Viewer Pyramid

sub to_string {}

1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

=head1 SYNOPSIS

 use BE4::Pyramid;
 
 # 1. a pyramid configured from an existing another
 
 my $params_options  = {
    #
    pyr_name_old => "SCAN_RAW_TESTOLD.pyr",
    pyr_name_new => "SCAN_RAW_TESTNEW.pyr",
    pyr_descpath => "./t/data/pyramid/",
    pyr_datapath => "./t/data/pyramid/ORTHO",
    #
    tms_path     => "./t/data/tms/",
    #
    dir_depth    => "2",  
    dir_image    => "IMAGE",
    dir_metadata => "METADATA",
    #
    path_nodata   => "./t/data/nodata/",
    imagesize     => "1024",
    color         => "FFFFFF,
    #
    interpolation => "bicubique",
    photometric   => "rgb",
 };

 my $objP = BE4::Pyramid->new($params_options);
 
 $objP->writeConfPyramid();           # in ./t/data/pyramid/SCAN_RAW_TESTNEW.pyr !
 $objP->writeConfPyramid("TEST.pyr"); # in ./t/data/pyramid/TEST.pyr !
 
 $objP->writeCachePyramid();  # in 'pyr_datapath' determined by pyramid ! 
 $objP->writeCachePyramid("./t/data/pyramid/test/"); # in another path !
 
 # 2. a new pyramid
 
 my $params_options = {
    #
    pyr_name_new => "SCAN_RAW_TESTNEW.pyr",
    pyr_descpath => "./t/data/pyramid/",
    pyr_datapath => "./t/data/pyramid/",
    # 
    tms_name     => "LAMB93_50cm_TEST.tms",
    tms_path     => "./t/data/tms/",
    #
    compression  => "raw",
    #
    dir_depth    => "2",
    dir_image    => "IMAGE",
    dir_metadata => "METADATA",
    #
    image_width  => "16", 
    image_height => "16",
    # 
    path_nodata   => "./t/data/nodata/",
    imagesize     => "1024",
    color         => "FFFFFF",
    #
    bitspersample       => "8", 
    sampleformat        => "uint", 
    ; compressionscheme   => "none", 
    photometric         => "rgb", 
    samplesperpixel     => "3",
    interpolation       => "bicubique",
 };

 my $objP = BE4::Pyramid->new($params_options);

 $objP->writeConfPyramid();  # in ./t/data/pyramid/SCAN_RAW_TESTNEW.pyr !
 $objP->writeCachePyramid(); # in ./t/data/pyramid/


=head1 DESCRIPTION

=over

=item * create a new pyramid

To create a new pyramid, you must fill all parameters following :

    pyr_name_new  =
    pyr_descpath  =
    pyr_datapath  =
    #
    compression   => by default, it's 'raw' !
    #
    image_width   = 
    image_height  =
    #
    dir_depth     =  
    dir_image     = 
    dir_metadata  = 
    # 
    tms_name      =
    tms_path      = 
    # 
    path_nodata   =
    imagesize     => by default, it's '4096' !
    color         => by default, it's 'FFFFFF' !
    # 
    bitspersample       = 
    sampleformat        = 
    # compressionscheme   = 
    photometric         => by default, it's 'rgb' !
    samplesperpixel     =
    interpolation       => by default, it's 'bicubique' !

The pyramid file and the directory structure can be create.

=item * create a new pyramid from an existing pyramid

To create a new pyramid, you must fill all parameters following :

    pyr_name_old  =
    pyr_name_new  =
    pyr_descpath  =
    pyr_datapath  =
    #
    dir_depth    =  
    dir_image    = 
    #
    tms_path      = 
    # 
    path_nodata   =
    imagesize     => by default, it's '4096' !
    color         => by default, it's 'FFFFFF' !
    # 
    interpolation => by default, it's 'rgb' !
    photometric   => by default, it's 'bicubique' !

All paramaters are filled by loading the old configuration pyramid.
So, object 'BE4::Product' and 'BE4::TileMatrixSet' are created, and the other
parameters are filled...

The pyramid file can be create. The Directory structure of the old pyramid can be
duplicate to the new target directory.

=item * create a file configuration of pyramid

For an new pyramid, all level of the tms file are saved into.
For an existing pyramid, all level of the existing pyramid are only duplicated and
it's the tms value name of the existing pyramid that's considered valid!

=item * create a directory structure

For an new pyramid, the directory structure is empty, only the level directory
are written on disk !
ie :
 ROOTDIR/
  |__PYRAMID_NAME/
        |__IMAGE/
            |__ ID_LEVEL0/
            |__ ID_LEVEL1/
            |__ ID_LEVEL2/

But for an existing pyramid, the directory structure is duplicated to the new
pyramid with all file linked !
ie :
 ROOTDIR/
  |__PYRAMID_NAME/
        |__IMAGE/
            |__ ID_LEVEL0/
                |__ 00/
                    |__ 7F/
                    |__ 7G/
                        |__ CV.tif 
                        |__ ...
            |__ ID_LEVEL1/
            |__ ID_LEVEL2/
                |__ ...
                
    with
     ls -l CV.tif
     CV.tif -> ../../../../../PYRAMID_NAME_OLD/IMAGE/ID_LEVEL0/7G/CV.tif

So be careful when you create a new tile in a directory structure of pyramid,
you must test if the linker exist ! If not, you can destroy the old tile !

=back

=head2 EXPORT

None by default.

=head1 DIRECTORY STRUCTURE

=over

=item * Directory structure :
  
  ${ROOTDIR}/
    |_____ ${PYRAMID_NAME}/
           (ie ortho_raw_dept75)
                |_____ ${IMAGE}/
                            |__ ${ID_LEVEL0}/
                                |__ DEPTH(BASE36)
                                        |__X(BASE36)/
                                            |__ Y(BASE36).tif (it's a link !)
                                            |__ ...
                            |__ ${ID_LEVEL1}/
                            |__ ${ID_LEVELN}/
                |_____ ${METADATA}/
                |_____ ${PYRAMID_FILE}
                        (ie ortho_raw_dept75.xml)

  with the variables following :
    ROOTDIR
    PYRAMID_NAME
    ID_LEVEL(0)  
    IMAGE
    METADATA
    PYRAMID_FILE

=item * Rule Image/Directory Naming :
  
  Res  : 2 m  (determined by level)
  Xmin : 933888.00
  Ymax : 6537216.00
  Size : 8192 m (imagesize = 4096*4096)
  Level: 3
  Index X = 933888/8192 = 114
  Index Y = (16777216-6537216)/8192 = 1250
  Index X base 36 = 36
  Index Y base 36 = QY
  Index X base 36 (write with 3 number) = 036
  Index Y base 36 (write with 3 number) = 0QY
  The directory structure and the image name was defined :
    /$ROOTDIR/$PYRAMID_NAME/IMAGE/3/00/3Q/6Y.tif.

=back

=head1 SAMPLE

=over

=item * Sample Pyramid file (.pyr) :

  [SCAN_RAW_TEST.pyr]
  
  <?xml version='1.0' encoding='US-ASCII'?>
  <Pyramid>
	<tileMatrixSet>LAMB93_50cm_TEST</tileMatrixSet>
	<level>
		<tileMatrix>18</tileMatrix>
		<baseDir>../config/pyramids/SCAN_RAW_TEST/512</baseDir>
		<format>TIFF_INT8</format>
		<metadata type='INT32_DB_LZW'>
			<baseDir>../config/pyramids/SCAN_RAW_TEST/512</baseDir>
			<format>TIFF_INT8</format>
		</metadata>
		<channels>3</channels>
		<tilesPerWidth>4</tilesPerWidth>
		<tilesPerHeight>4</tilesPerHeight>
		<pathDepth>2</pathDepth>
		<TMSLimits>
			<minTileRow>1</minTileRow>
			<maxTileRow>1000000</maxTileRow>
			<minTileCol>1</minTileCol>
			<maxTileCol>1000000</maxTileCol>
		</TMSLimits>
	</level>
	<level>
		<tileMatrix>17</tileMatrix>
		<baseDir>../config/pyramids/SCAN_RAW_TEST/1024</baseDir>
		<format>TIFF_INT8</format>
		<metadata type='INT32_DB_LZW'>
			<baseDir>../config/pyramids/SCAN_RAW_TEST/1024</baseDir>
			<format>TIFF_INT8</format>
		</metadata>
		<channels>3</channels>
		<tilesPerWidth>4</tilesPerWidth>
		<tilesPerHeight>4</tilesPerHeight>
		<pathDepth>2</pathDepth>
		<TMSLimits>
			<minTileRow>1</minTileRow>
			<maxTileRow>1000000</maxTileRow>
			<minTileCol>1</minTileCol>
			<maxTileCol>1000000</maxTileCol>
		</TMSLimits>
	</level>
  </Pyramid>

=item * Sample TMS file (.tms) :

  eg SEE ASLO

=item * Sample LAYER file (.lay) :

  eg SEE ASLO

=back

=head1 LIMITATIONS AND BUGS

 File name of pyramid must be with extension : pyr or PYR !
 All levels must be continuous and unique !

=head1 SEE ALSO

 eg package module following :
 
 BE4::Layer
 BE4::TileMatrixSet

=head1 AUTHOR

Bazonnais Jean Philippe, E<lt>jpbazonnais@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Bazonnais Jean Philippe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut