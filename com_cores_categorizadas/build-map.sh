# transforma para JSON, tornando o mesmo maior
shp2json pb_setores_censitarios/25SEE250GC_SIR.shp -o pb.json

# converte imagem com coordenadas de um globo para projeção
geoproject 'd3.geoOrthographic().rotate([54, 14, -2]).fitSize([1000, 600], d)' < pb.json > pb-ortho.json

# converte a projeção para SVG, para poder visualizar
geo2svg -w 1000 -h 600 < pb-ortho.json > pb-ortho.svg

# converte json para NDJSON, um arquivo em que cada unidade está em uma linha
ndjson-split 'd.features' < pb-ortho.json > pb-ortho.ndjson

# V089 Mulheres moradoras em domicílios particulares e domicílios coletivos
# Domicilio02_PB.csv

EXP_PROPRIEDADE='d[0].properties = {mulheres: Number(d[1].V083)}, d[0]'

EXP_ESCALA='z = d3.scaleThreshold().domain([0, 250, 500, 750, 1100]).range(d3.schemeSpectral[5]), d.features.forEach(f => f.properties.fill = z(f.properties.mulheres)), d'

ndjson-map 'd.Cod_setor = d.properties.CD_GEOCODI, d' < pb-ortho.ndjson > pb-ortho-sector.ndjson

dsv2json --input-encoding latin1 -r ';' -n < Domicilio02_PB.csv > pb-censo.ndjson
ndjson-join 'd.Cod_setor' pb-ortho-sector.ndjson pb-censo.ndjson > pb-ndjson-join.ndjson

ndjson-map "$EXP_PROPRIEDADE"  < pb-ndjson-join.ndjson  | geo2topo -n  tracts=-  | toposimplify -p 1 -f  | topoquantize 1e5   | topo2geo tracts=- | ndjson-map -r d3 -r d3=d3-scale-chromatic  "$EXP_ESCALA"  | ndjson-split 'd.features' | geo2svg -n --stroke none -w 1000 -h 600  > pb-chroropleth.svg


EXP_PROPRIEDADE='d[0].properties = {mulheresP: (Number(d[1].V083)*100/Number(d[1].V001))}, d[0]'

EXP_ESCALA='z = d3.scaleThreshold().domain([0, 25, 50, 75, 100]).range(d3.schemeSpectral[5]), d.features.forEach(f => f.properties.fill = z(f.properties.mulheresP)), d'

ndjson-map 'd.Cod_setor = d.properties.CD_GEOCODI, d' < pb-ortho.ndjson > pb-ortho-sector.ndjson

dsv2json --input-encoding latin1 -r ';' -n < Domicilio02_PB.csv > pb-censo.ndjson
ndjson-join 'd.Cod_setor' pb-ortho-sector.ndjson pb-censo.ndjson > pb-ndjson-join.ndjson

ndjson-map "$EXP_PROPRIEDADE"  < pb-ndjson-join.ndjson  | geo2topo -n  tracts=-  | toposimplify -p 1 -f  | topoquantize 1e5   | topo2geo tracts=- | ndjson-map -r d3 -r d3=d3-scale-chromatic  "$EXP_ESCALA"  | ndjson-split 'd.features' | geo2svg -n --stroke none -w 1000 -h 600  > pb-chroropleth2.svg
