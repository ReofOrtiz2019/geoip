Autor: Rodrigo Erensto Ortiz Florez

El proyecto1.sol con dirección 
0x7461e672dA08048b298f30A182168d9ab40E5858
Busca un IP publica en un servicio que retorna la latitud y longitud, para lo cual utiliza un oráculo denominado Chanlink que permite la consulta del servicio e ingresar los datos a la blockchain.

El proyecto2.sol con dirección 
0xA6b7b2986B7bF6c134401a1cD6CB727d2EB9292A
Busca la ip en un servicio que retorna la latitud y la longitud, utilizando un oráculo con en el primer proyecto, la variación consiste en el uso de esta estructura para almacenar la información

    struct Ip {
        string ip;
        string longitud;
        string latitud;
}
Lo que implica una búsqueda de la IP npublica en la estructura para minimizar los tiempos de respuesta y el gas utiliza, al no pasar por el oráculo





