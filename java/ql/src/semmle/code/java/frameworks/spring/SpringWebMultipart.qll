/** Provides models of taint flow in `org.springframework.web.multipart` */
import java

/** Provides models of taint flow in `org.springframework.web.multipart` */
module SpringWebMultipart {
  private class FlowSummaries extends SummaryModelCsv {
    override predicate row(string row) {
      row = [
        "org.springframework.web.multipart;MultipartFile;true;getBytes;;;Argument[-1];ReturnValue;taint",
        "org.springframework.web.multipart;MultipartFile;true;getInputStream;;;Argument[-1];ReturnValue;taint",
        "org.springframework.web.multipart;MultipartFile;true;getName;;;Argument[-1];ReturnValue;taint",
        "org.springframework.web.multipart;MultipartFile;true;getOriginalFileName;;;Argument[-1];ReturnValue;taint",
        "org.springframework.web.multipart;MultipartFile;true;getResource;;;Argument[-1];ReturnValue;taint",
        "org.springframework.web.multipart;MultipartHttpServletRequest;true;getMultipartHeaders;;;Argument[-1];ReturnValue;taint"
        "org.springframework.web.multipart;MultipartHttpServletRequest;true;getRequestHeaders;;;Argument[-1];ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getFile;;;Argument[-1];ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getFileMap;;;Argument[-1];MapValue of ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getFileNames;;;Argument[-1];Element of ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getFiles;;;Argument[-1];Element of ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getMultiFileMap;;;Argument[-1];MapValue of ReturnValue;taint"
        "org.springframework.web.multipart;MultipartRequest;true;getResource;;;Argument[-1];ReturnValue;taint"
      ]
    }
  }
}
