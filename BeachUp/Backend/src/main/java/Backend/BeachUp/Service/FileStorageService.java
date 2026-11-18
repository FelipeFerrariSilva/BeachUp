package Backend.BeachUp.Service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@Slf4j
public class FileStorageService {

    private final Cloudinary cloudinary;

    public FileStorageService(
            @Value("${cloudinary.cloud-name}") String cloudName,
            @Value("${cloudinary.api-key}")    String apiKey,
            @Value("${cloudinary.api-secret}") String apiSecret) {

        this.cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key",    apiKey,
                "api_secret", apiSecret,
                "secure",     true
        ));
    }


    public String salvar(MultipartFile arquivo, String subpasta) {
        if (arquivo == null || arquivo.isEmpty()) {
            return null;
        }

        try {
            Map<?, ?> resultado = cloudinary.uploader().upload(
                    arquivo.getBytes(),
                    ObjectUtils.asMap(
                            "folder",         "beachup/" + subpasta,
                            "resource_type",  "auto"
                    )
            );
            return (String) resultado.get("secure_url");
        } catch (IOException e) {
            throw new RuntimeException("Erro ao fazer upload para o Cloudinary: " + e.getMessage(), e);
        }
    }


    public void remover(String url) {
        if (url == null || url.isBlank()) {
            return;
        }

        try {
            String publicId = extrairPublicId(url);
            if (publicId == null) {
                log.warn("Nao foi possivel extrair public_id da URL: {}", url);
                return;
            }
            cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
        } catch (IOException e) {
            log.error("Erro ao remover arquivo do Cloudinary (url={}): {}", url, e.getMessage());
        }
    }


    private String extrairPublicId(String url) {

        try {
            String marcador = "/upload/";
            int idx = url.indexOf(marcador);
            if (idx < 0) return null;

            String aposUpload = url.substring(idx + marcador.length());


            if (aposUpload.matches("v\\d+/.*")) {
                aposUpload = aposUpload.substring(aposUpload.indexOf('/') + 1);
            }


            int pontoIdx = aposUpload.lastIndexOf('.');
            if (pontoIdx >= 0) {
                aposUpload = aposUpload.substring(0, pontoIdx);
            }

            return aposUpload;
        } catch (Exception e) {
            log.error("Erro ao extrair public_id de: {}", url);
            return null;
        }
    }
}