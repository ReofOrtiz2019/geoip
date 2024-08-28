// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract GeoIpAdress is FunctionsClient {

    struct Ip {
        string ip;
        string longitud;
        string latitud;
    }

    Ip[] public Ips;

    using FunctionsRequest for FunctionsRequest.Request;
    bytes32 public ultimoRequestId;
    string public ipAdress;

    address ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint32 GAS_LIMIT = 300000;

    string CODIGO_FUENTE =
        "const ipAdress = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://ipwho.is/${ipAdress}`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Solicitud fallida');"
        "}"
        "const latitude= apiResponse.data.latitude;"
        "const longitude= apiResponse.data.longitude;"
        "return Functions.encodeString(`${latitude},${longitude}`);";

    event Respuesta(
        bytes32 indexed requestId,
        string ipAdress
    );
    
    constructor() FunctionsClient(ROUTER) {}

    function BuscarIp(string memory _ip) public view returns (string memory, string memory) {
        for (uint i = 0; i < Ips.length; i++) {
            Ip storage IpA = Ips[i];
            if (keccak256(abi.encodePacked(IpA.ip)) == keccak256(abi.encodePacked(_ip))) {
                return (IpA.latitud, IpA.longitud);
            }
        }
        return ('0','0');
    }

    function enviarSolicitud(
        uint64 subscriptionId,
        string[] calldata args
    ) external returns (bytes32 requestId) {
        // Verificar si la IP ya está en la blockchain antes de hacer la solicitud
        (string memory latitud, string memory longitud) = BuscarIp(args[0]);
        if (keccak256(abi.encodePacked(latitud)) != keccak256(abi.encodePacked('0')) &&
            keccak256(abi.encodePacked(longitud)) != keccak256(abi.encodePacked('0'))) {
            // La IP ya está almacenada, no se necesita hacer la solicitud
            ipAdress = string(abi.encodePacked(latitud, ",", longitud));
            emit Respuesta(bytes32(0), ipAdress); // Emite un evento con los datos existentes
            return bytes32(0); // Retorna un ID nulo para indicar que no se hizo una solicitud
        }

        // Si la IP no está almacenada, se procede a hacer la solicitud
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CODIGO_FUENTE); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        ultimoRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            GAS_LIMIT,
            DON_ID
        );

        return ultimoRequestId;
    }

    function agregarIpAdress(string memory ip, string memory latitud, string memory longitud) public {
        Ips.push(Ip(ip, latitud, longitud));
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory
    ) internal override {
        if (ultimoRequestId == requestId) {
            ipAdress = string(response);
            // Parsear la respuesta para obtener latitud y longitud
            (string memory latitud, string memory longitud) = parseResponse(response);

            // Agregar la IP y su información a la lista
            agregarIpAdress(ipAdress, latitud, longitud);

            // Emitir el evento con la respuesta
            emit Respuesta(requestId, ipAdress);
        }
    }

    // Función para parsear la respuesta en latitud y longitud
    function parseResponse(bytes memory response) internal pure returns (string memory, string memory) {
        // Asumiendo que la respuesta es una cadena con formato "latitud,longitud"
        string[] memory parts = split(string(response), ",");
        return (parts[0], parts[1]);
    }

    // Función auxiliar para dividir una cadena en partes
    function split(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        uint partsCount = 1;
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                partsCount++;
            }
        }
        
        string[] memory parts = new string[](partsCount);
        uint partIndex = 0;
        string memory part = "";
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[partIndex] = part;
                part = "";
                partIndex++;
            } else {
                part = string(abi.encodePacked(part, bytes(str)[i]));
            }
        }
        parts[partIndex] = part;
        return parts;
    }
}
