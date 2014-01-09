package Vyatta::AccelPPPConfig;

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::Config;
use Vyatta::Misc;
use NetAddr::IP;

my $cfg_delim_begin = '### Vyatta Accel PPPOE Begin ###';
my $cfg_delim_end = '### Vyatta Accel PPPOE End ###';

my %fields = (
    _client_ip_start  => undef,
    _client_ip_stop   => undef,
    _auth_mode        => undef,
    _mtu              => undef,
    _ac               => undef,
    _service          => undef,
    _auth_local       => [],
    _auth_radius      => [],
    _auth_radius_keys => [],
    _dns              => [],
    _wins             => [],
    _intfs            => [],
    _is_empty         => 1,
);

sub new {
    my $that = shift;
    my $class = ref ($that) || $that;
    my $self = {
        %fields,
    };
    
    bless $self, $class;
    return $self;
}

sub setup_base {
    my ($self, $listNodes_func, $val_func, $vals_func, $exists_func) = @_;

    my $config = new Vyatta::Config;
    $config->setLevel('service accel-ppp pppoe');
    my @nodes = $config->$listNodes_func();
    if (scalar(@nodes) <= 0) {
        $self->{_is_empty} = 1;
        return 0;
    } else {
        $self->{_is_empty} = 0;
    }

    $self->{_client_ip_start} = $config->$val_func('client-ip-pool start');
    $self->{_client_ip_stop} = $config->$val_func('client-ip-pool stop');
    $self->{_auth_mode} = $config->$val_func('authentication mode');
    $self->{_mtu} = $config->$val_func('mtu');
    $self->{_mru} = $config->$val_func('mru');
    $self->{_ac} = $config->$val_func('access-concentrator');
    $self->{_service} = $config->$val_func('service-name');
    
    my @users = $config->$listNodes_func('authentication local-users username');
    foreach my $user (@users) {
        my $plvl = "authentication local-users username $user password";
        my $pass = $config->$val_func("$plvl");
        my $dlvl = "authentication local-users username $user disable";
        my $disable = 'enable';
        $disable = 'disable' if $config->$exists_func("$dlvl");
        my $ilvl = "authentication local-users username $user static-ip";
        my $ip = $config->$val_func("$ilvl");
        $ip = 'none' if ! defined $ip;
        $self->{_auth_local} = [ @{$self->{_auth_local}}, $user, $pass, 
                                 $disable, $ip ];
    }
  
    my @rservers = $config->$listNodes_func('authentication radius-server');
    foreach my $rserver (@rservers) {
        my $klvl = "authentication radius-server $rserver key";
        my $key = $config->$val_func($klvl);
        $self->{_auth_radius} = [ @{$self->{_auth_radius}}, $rserver ];
        if (defined($key)) {
            $self->{_auth_radius_keys} = [ @{$self->{_auth_radius_keys}}, $key ];
        }
        # later we will check if the two lists have the same length
    }
    my @intfs = $config->$vals_func('interface');
    foreach my $intf (@intfs) {
        $self->{_intfs} = [ @{$self->{_intfs}}, $intf];
    }
    
    my $tmp = $config->$val_func('dns-servers server-1');
    if (defined($tmp)) {
        $self->{_dns} = [ @{$self->{_dns}}, $tmp ];
    }
    $tmp = $config->$val_func('dns-servers server-2');
    if (defined($tmp)) {
        $self->{_dns} = [ @{$self->{_dns}}, $tmp ];
    }
    
    $tmp = $config->$val_func('wins-servers server-1');
    if (defined($tmp)) {
        $self->{_wins} = [ @{$self->{_wins}}, $tmp ];
    }
    $tmp = $config->$val_func('wins-servers server-2');
    if (defined($tmp)) {
        $self->{_wins} = [ @{$self->{_wins}}, $tmp ];
    }
    
    return 0;
}

sub setup {
    my ($self) = @_;
    
    $self->setup_base('listNodes', 'returnValue', 'returnValues', 'exists');
    return 0;
}

sub setupOrig {
    my ($self) = @_;
    
    $self->setup_base('listOrigNodes', 'returnOrigValue', 'returnOrigValue', 
                      'existsOrig');
    return 0;
}

sub listsDiff {
    my @a = @{$_[0]};
    my @b = @{$_[1]};
    return 1 if scalar @a != scalar @b;
    
    while (my $a = shift @a) {
        my $b = shift @b;
        return 1 if ($a ne $b);
    }
    return 0;
}

sub isDifferentFrom {
    my ($this, $that) = @_;

    return 1 if ($this->{_is_empty} ne $that->{_is_empty});
    return 1 if ($this->{_client_ip_start} ne $that->{_client_ip_start});
    return 1 if ($this->{_client_ip_stop} ne $that->{_client_ip_stop});
    return 1 if ($this->{_auth_mode} ne $that->{_auth_mode});
    return 1 if ($this->{_mtu} ne $that->{_mtu});
    return 1 if ($this->{_ac} ne $that->{_ac});
    return 1 if ($this->{_service} ne $that->{_service});

    return 1 if (listsDiff($this->{_auth_local}, $that->{_auth_local}));
    return 1 if (listsDiff($this->{_auth_radius}, $that->{_auth_radius}));
    return 1 if (listsDiff($this->{_auth_radius_keys},
                           $that->{_auth_radius_keys}));
    return 1 if (listsDiff($this->{_dns}, $that->{_dns}));
    return 1 if (listsDiff($this->{_wins}, $that->{_wins}));
    return 1 if (listsDiff($this->{_intfs}, $that->{_intfs}));
    
    return 0;
}

sub needsRestart {
    my ($this, $that) = @_;

    return 1 if ($this->{_is_empty} ne $that->{_is_empty});
    return 1 if ($this->{_client_ip_start} ne $that->{_client_ip_start});
    return 1 if ($this->{_client_ip_stop} ne $that->{_client_ip_stop});
    return 1 if ($this->{_mtu} ne $that->{_mtu});
    return 1 if ($this->{_ac} ne $that->{_ac});
    return 1 if ($this->{_service} ne $that->{_service});
    return 1 if (listsDiff($this->{_intfs}, $that->{_intfs}));
    return 1 if (listsDiff($this->{_dns}, $that->{_dns}));
    return 1 if (listsDiff($this->{_wins}, $that->{_wins}));

    return 0;
}

sub isEmpty {
    my ($self) = @_;
    return $self->{_is_empty};
}

sub get_ppp_opts {
    my ($self) = @_;

    my @intfs = @{$self->{_intfs}};
    	return (undef, "Must define at least 1 interface")
    	if scalar(@intfs) < 1;
    	
    my @dns = @{$self->{_dns}};
    my @wins = @{$self->{_wins}};
    my $sstr = '';
    foreach my $d (@dns) {
        $sstr .= "ms-dns $d\n";
    }
    foreach my $w (@wins) {
        $sstr .= "ms-wins $w\n";
    }
    my $rstr = '';
    if ($self->{_auth_mode} eq 'radius') {
        $rstr  = "plugin radius.so\n";
        $rstr .= "radius-config-file ";
        $rstr .= " /etc/radiusclient-ng/radiusclient-pppoe.conf\n";
        $rstr .= "plugin radattr.so\n";
    }
    my $str;
    $str  = "$cfg_delim_begin\n";
    $str .= "[modules]\nlog_file\npppoe\nauth_chap_md5\nradius\nippool\nshaper\n";
    $str .= "[core]\nlog-error=/var/log/accel-ppp/core.log\nthread-count=2\n";
    $str .= "[ppp]\n";
    $str .= "verbose=10\n";
    $str .= "min-mtu=1400\n";
    if (defined ($self->{_mtu})){
	$str .= "mtu=$self->{_mtu}\n";
	$str .= "mru=$self->{_mru}\n";
    }
    $str .= "ccp=1\n";
    $str .= "#check-ip=0\n";
    $str .= "mppe=deny\n";
    $str .= "ipv4=require\n";
    $str .= "ipv6=deny\n";
    $str .= "ipv6-intf-id=0:0:0:1\n";
    $str .= "ipv6-peer-intf-id=0:0:0:2\n";
    $str .= "ipv6-accept-peer-intf-id=1\n";
    $str .= "lcp-echo-interval=60\n";
    $str .= "lcp-echo-failure=3\n";
    $str .= "lcp-echo-timeout=60\n";
    $str .= "unit-cache=50\n";
    $str .= "\n";
    
    $str .= "[pppoe]\n";
    $str .= "verbose=10\n";
    $str .= "ac-name=$self->{_ac}\n";
    if (defined ($self->{_service})){
    	$str .= "service-name=$self->{_service}\n";
    } else {
    	$str .= "service-name=*\n";
    }
    $str .= "#pado-delay=0\n";
    $str .= "#pado-delay=0,100:100,200:200,-1:500\n";
    $str .= "#ifname-in-sid=called-sid\n";
    $str .= "#tr101=1\n";
    $str .= "#padi-limit=0\n";
    $str .= "ip-pool=testa\n";
    $str .= "#interface=eth1,padi-limit=1000\n";
    while (scalar(@intfs) > 0) {
    	my $intf = shift @intfs;
        $str .= "interface=$intf\n";
    }
    $str .= "\n";

    # TODO
    $str .= "[dns]\n";
    $str .= "dns1=201.20.160.5\n";
    $str .= "dns2=201.20.160.15\n";
    $str .= "\n";
    
    # TODO
    $str .= "[radius]\n";
    $str .= "#dictionary=/usr/local/share/accel-ppp/radius/dictionary\n";
    $str .= "nas-identifier=accel-ppp\n";
    $str .= "nas-ip-address=127.0.0.1\n";
    $str .= "gw-ip-address=192.168.100.1\n";
    $str .= "server=127.0.0.1,testing123,auth-port=1812,acct-port=1813,req-limit=0,fail-time=0\n";
    $str .= "dae-server=127.0.0.1:3799,testing123\n";
    $str .= "verbose=1\n";
    $str .= "#timeout=3\n";
    $str .= "#max-try=3\n";
    $str .= "#acct-timeout=120\n";
    $str .= "#acct-delay-time=0\n";
    $str .= "#acct-on=0\n";
    $str .= "\n";
    
    # TODO
    $str .= "[ip-pool]\n";
    $str .= "gw-ip-address=192.168.0.1\n";
    $str .= "#vendor=Cisco\n";
    $str .= "#attr=Cisco-AVPair\n";
    $str .= "attr=Framed-Pool\n";
    $str .= "192.168.3.0-2,name=testa\n";
    $str .= "\n";
    
    $str .= "[log]\n";
    $str .= "log-file=/var/log/accel-ppp/accel-ppp.log\n";
    $str .= "log-emerg=/var/log/accel-ppp/emerg.log\n";
    $str .= "log-fail-file=/var/log/accel-ppp/auth-fail.log\n";
    $str .= "copy=1\n";
    $str .= "level=1\n";
    $str .= "\n";

    $str .= "[shaper]\n";
    $str .= "#attr=Filter-Id\n";
    $str .= "#down-burst-factor=0.1\n";
    $str .= "#up-burst-factor=1.0\n";
    $str .= "#latency=50\n";
    $str .= "#mpu=0\n";
    $str .= "#mtu=0\n";
    $str .= "#r2q=10\n";
    $str .= "#quantum=1500\n";
    $str .= "#cburst=1534\n";
    $str .= "#ifb=ifb0\n";
    $str .= "up-limiter=police\n";
    $str .= "down-limiter=tbf\n";
    $str .= "#leaf-qdisc=sfq perturb 10\n";
    $str .= "#rate-multiplier=1\n";
    $str .= "verbose=1\n";
    $str .= "\n";

    $str .= "[cli]\n";
    $str .= "telnet=127.0.0.1:2000\n";
    $str .= "tcp=127.0.0.1:2001\n";
    $str .= "#password=123\n";

    $str .= "$cfg_delim_end\n";
    return ($str, undef);
}

sub get_ip_str {
    my ($start, $stop) = @_;

    my $ip1 = new NetAddr::IP "$start/24";
    my $ip2 = new NetAddr::IP "$stop/24";
    if ($ip1->network() != $ip2->network()) {
        return (undef, 'Client IP pool not within a /24');
    }
    if ($ip1 >= $ip2) {
        return (undef, 'Stop IP must be higher than start IP');
    }

    my ($start_digit, $stop_digit, $num) = (undef, undef, undef);

    $start =~ m/\.(\d+)$/;
    $start_digit = $1;
    $stop =~ m/\.(\d+)$/;
    $stop_digit = $1;
    $num = ($stop_digit + 1) - $start_digit;
    
    return ("-L 10.255.253.0 -R $start -N $num -F", undef);
}

sub get_pppoe_cmdline {
    my ($self) = @_;

    my $str = '';
    my @intfs = @{$self->{_intfs}};
    return (undef, "Must define at least 1 interface")
        if scalar(@intfs) < 1;

    while (scalar(@intfs) > 0) {
        my $intf = shift @intfs;
        $str .= "-I $intf ";
    }

    my $cstart = $self->{_client_ip_start};
    return (undef, "Client IP pool start not defined") 
        if ! defined $cstart;

    my $cstop = $self->{_client_ip_stop};
    return (undef, "Client IP pool stop not defined") 
        if ! defined $cstop;

    my ($ip_str, $err) = get_ip_str($cstart, $cstop);
    return (undef, "$err") 
        if ! defined $ip_str;

    $str .= $ip_str . " -k ";
    $str .= " -C " . $self->{_ac} if defined $self->{_ac};
    $str .= " -S " . $self->{_service} if defined $self->{_service};

    return ($str, undef);
}

sub removeCfg {
    my ($self, $file) = @_;

    system("sed -i '/$cfg_delim_begin/,/$cfg_delim_end/d' $file");
    if ($? >> 8) {
        print STDERR 
            "PPPoE configuration error: Cannot remove old config from $file.\n";
        
        return 0;
    }
    return 1;
}

sub writeCfg {
    my ($self, $file, $cfg, $append, $delim) = @_;

    my $op = ($append) ? '>>' : '>';
    my $WR = undef;
    if (!open($WR, $op, "$file")) {
        print STDERR 
            "PPPoE configuration error: Cannot write config to $file.\n";
        return 0;
    }
    if ($delim) {
        $cfg = "$cfg_delim_begin\n" . $cfg . "\n$cfg_delim_end\n";
    }
    print ${WR} "$cfg";
    close $WR;
    return 1;
}

sub print_str {
    my ($self) = @_;

    my $str = 'pppoe-server';
    $str .= "\n  intfs " . (join ",", @{$self->{_intfs}});
    $str .= "\n  cip_start " . $self->{_client_ip_start};
    $str .= "\n  cip_stop " . $self->{_client_ip_stop};
    $str .= "\n  auth_mode " . $self->{_auth_mode};
    $str .= "\n  auth_local " . (join ",", @{$self->{_auth_local}});
    $str .= "\n  auth_radius " . (join ",", @{$self->{_auth_radius}});
    $str .= "\n  auth_radius_s " . (join ",", @{$self->{_auth_radius_keys}});
    $str .= "\n  dns " . (join ",", @{$self->{_dns}});
    $str .= "\n  wins " . (join ",", @{$self->{_wins}});
    $str .= "\n  empty " . $self->{_is_empty};
    $str .= "\n";

  return $str;
}

1;
