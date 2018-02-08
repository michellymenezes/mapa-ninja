export PATH=$PATH:./node_modules/.bin/

# transforma para JSON, tornando o mesmo maior
shp2json pb_setores_censitarios/25SEE250GC_SIR.shp -o pb.json

# converte imagem com coordenadas de um globo para projeção
geoproject 'd3.geoOrthographic().rotate([54, 14, -2]).fitSize([1000, 600], d)' < pb.json > pb-ortho.json

# converte a projeção para SVG, para poder visualizar
geo2svg -w 1000 -h 600 < pb-ortho.json > pb-ortho.svg

# converte json para NDJSON, um arquivo em que cada unidade está em uma linha
ndjson-split 'd.features' < pb-ortho.json > pb-ortho.ndjson

# transforma o csv em ndjson
dsv2json --input-encoding latin1 -r ';' -n < Domicilio02_PB.csv > pb-censo.ndjson

# Mapeia o codigo do setor
ndjson-map 'd.Cod_setor = d.properties.CD_GEOCODI, d' < pb-ortho.ndjson > pb-ortho-sector.ndjson

# realiza join de ambos
ndjson-join 'd.Cod_setor' pb-ortho-sector.ndjson pb-censo.ndjson > pb-ndjson-join.ndjson

# deixa apenas uma linha por objeto. Adiciona a variável V005 editada a properties do primeiro objeto do array e depois mantém só esse primeiro objeto
ndjson-map  'd[0].properties = {mulheres: Number(d[1].V089)}, d[0]' < pb-ndjson-join.ndjson > pb-ortho-comdado.ndjson

# transforma o ndjson para TopoJSON, isso reduz um pouco seu tamannho
geo2topo -n tracts=pb-ortho-comdado.ndjson > pb-tracts-topo.json

# reduz o tamanho do TopoJSON devido a simplificações e quantizações na geometria
toposimplify -p 1 -f < pb-tracts-topo.json | topoquantize 1e5 > pb-quantized-topo.json

# transforma o último json gerado em um svg
topo2geo tracts=- < pb-quantized-topo.json | ndjson-map -r d3 'z = d3.scaleSequential(d3.interpolateViridis).domain([0, 1e3]), d.features.forEach(f => f.properties.fill = z(f.properties.mulheres)), d' | ndjson-split 'd.features' | geo2svg -n --stroke none -w 1000 -h 600 > pb-tracts-threshold-light.svg



# V089 Mulheres moradoras em domicílios particulares e domicílios coletivos
# Domicilio02_PB.csv
