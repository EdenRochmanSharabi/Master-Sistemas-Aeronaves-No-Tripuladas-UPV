function kmlwrite_polyline(wp,filename,attr)
% Copy of kgbx-lib/kml/kmlwrite_polyline.m (course library), shadowing it.
% Only change: the Document <name> is attr.label or the bare file name.

[~, base, ext] = fileparts(filename);
docName = [base ext];
if isfield(attr,'label') && ~isempty(attr.label), docName = attr.label; end

fid1=fopen(filename,'w');
fprintf(fid1,'<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2">\n<Document>\n<name>%s</name>', docName);
fprintf(fid1,'\n<Style id="inline0">');
fprintf(fid1,'\n\t<LineStyle>\n\t\t<color>%s</color>\n\t\t<width>%s</width>\n\t</LineStyle>',attr.edgecolor,num2str(attr.edgewidth));
fprintf(fid1,'\n\t<IconStyle>\n\t\t<scale>%s</scale>\n\t\t<Icon><href>%s</href></Icon>\n\t</IconStyle>',num2str(attr.iconscale),attr.iconurl);
fprintf(fid1,'\n\t<LabelStyle>\n\t\t<color>%s</color>\n\t\t<scale>%s</scale>\n\t</LabelStyle>',attr.labelcolor,num2str(attr.labelscale));
fprintf(fid1,'\n</Style>');

fprintf(fid1,'\n<Style id="inline1">');
fprintf(fid1,'\n\t<LineStyle>\n\t\t<color>%s</color>\n\t\t<width>%s</width>\n\t</LineStyle>',attr.edgecolor,num2str(attr.edgewidth));
fprintf(fid1,'\n\t<IconStyle>\n\t\t<scale>%s</scale>\n\t\t<Icon><href>%s</href></Icon>\n\t</IconStyle>',num2str(attr.wpiconscale),attr.wpiconurl);
fprintf(fid1,'\n\t<LabelStyle>\n\t\t<color>%s</color>\n\t\t<scale>%s</scale>\n\t</LabelStyle>',attr.wplabelcolor,num2str(attr.wplabelscale));
fprintf(fid1,'\n</Style>');


fprintf(fid1,'\n<Placemark>\n\t<name>%s</name>\n\t<styleUrl>#inline0</styleUrl>',attr.label);
fprintf(fid1,'\n\t<MultiGeometry>');

m=round(length(wp)/2);
fprintf(fid1,'\n\t\t<Point>\n\t\t\t<altitudeMode>%s</altitudeMode>\n\t\t\t<coordinates>%3.6f,%3.6f,%3.6f</coordinates>\n\t\t</Point>',attr.altmode,wp(m).lon+.0001,wp(m).lat+.0001,wp(m).alt);

if (attr.edgewidth>0)
    fprintf(fid1,'\n\t\t<LineString>\n\t\t\t<extrude>%s</extrude>\n\t\t\t<tessellate>1</tessellate>\n\t\t\t<altitudeMode>%s</altitudeMode>\n\t\t\t<coordinates>',num2str(attr.extrude),attr.altmode);
    for j=1:length(wp)
        fprintf(fid1,'\n\t\t\t%3.6f,%3.6f,%3.6f ',wp(j).lon,wp(j).lat,wp(j).alt);
    end
    fprintf(fid1,'\n\t\t\t</coordinates>\n\t\t</LineString>');
end

fprintf(fid1,'\n\t</MultiGeometry>\n</Placemark>');

for j=1:length(wp)
    if ~strcmp(wp(j).name,'')
        fprintf(fid1,'\n<Placemark>');
        fprintf(fid1,'\n\t<name>%s</name>', wp(j).name);
        if ~strcmp(wp(j).desc,'')
            fprintf(fid1,'\n\t<description>%s</description>',wp(j).desc);
        end
        fprintf(fid1,'\n\t<styleUrl>inline1</styleUrl>');
        fprintf(fid1,'\n\t<Point>');
        fprintf(fid1,'\n\t\t<altitudeMode>%s</altitudeMode>',attr.altmode);
        fprintf(fid1,'\n\t\t<coordinates>');
        fprintf(fid1,'%3.6f,%3.6f,%3.6f ',wp(j).lon,wp(j).lat,wp(j).alt);
        fprintf(fid1,'</coordinates>');
        fprintf(fid1,'\n\t</Point>\n</Placemark>');
    end
end

fprintf(fid1,'\n</Document>\n</kml>');
fclose(fid1);
