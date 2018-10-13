#! /bin/sh

grunt clean:build && grunt bower:dev && grunt syncAssets && grunt replace:cssFancybox && grunt replace:cssTranquilpeak && grunt concat && grunt cssmin && grunt uglify && grunt linkAssetsProd

