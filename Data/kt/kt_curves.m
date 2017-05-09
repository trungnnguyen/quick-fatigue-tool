%% Kt Curves for surface finish definition files
%
%{
    Note: If the UTS exceeds the maximum available value, the last Kt value
          will be used.
%}
%
%% 'default.kt'
%{
    KT_CURVE    SURFACE DESCRIPTION
    1           Mirror Polished - Ra <= 0.25um
    2           0.25 < Ra <= 0.6um
    3           0.6 < Ra <= 1.6um
    4           1.6 < Ra <= 4um
    5           Fine Machined - 4 < Ra <= 16um
    6           Machined - 16 < Ra <= 40um
    7           Precision Forging - 40 < Ra <= 75um
    8           75um < Ra
%}
%    UTS Range: 0 to 1200MPa
%
%% 'juvinall-1967.kt'
%{
    KT_CURVE    SURFACE DESCRIPTION
    1           Mirror Polished
    2           Fine-ground or commercially polished
    3           Machined
    4           Hot-rolled
    5           As forged
    6           Corroded in tap water
    7           Corroded in salt water
%}
%    UTS Range: 0 to 360ksi
%
%% 'rcjohnson-1973.kt'
%{
    KT_CURVE    SURFACE DESCRIPTION
    1           AA = 1uins
    2           AA = 2uins
    3           AA = 4uins
    4           AA = 8uins
    5           AA = 16uins
    6           AA = 32uins
    7           AA = 83uins
    8           AA = 125uins
    9           AA = 250uins
    10          AA = 500uins
    11          AA = 1000uins
    12          AA = 2000uins
%}
%    UTS Range: 0 to 360ksi