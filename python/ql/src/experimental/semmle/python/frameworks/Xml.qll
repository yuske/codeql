/**
 * Provides class and predicates to track external data that
 * may represent malicious XML objects.
 */

private import python
private import semmle.python.dataflow.new.DataFlow
private import experimental.semmle.python.Concepts
private import semmle.python.ApiGraphs

private module Xml {
  /**
   * Gets a call to `xml.etree.ElementTree.XMLParser`.
   */
  private class XMLEtreeParser extends DataFlow::CallCfgNode, XML::XMLParser::Range {
    XMLEtreeParser() {
      this =
        API::moduleImport("xml")
            .getMember("etree")
            .getMember("ElementTree")
            .getMember("XMLParser")
            .getACall()
    }

    override DataFlow::Node getAnInput() { none() }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) { none() }
  }

  /**
   * Gets a call to:
   * * `xml.etree.ElementTree.fromstring`
   * * `xml.etree.ElementTree.fromstringlist`
   * * `xml.etree.ElementTree.XML`
   * * `xml.etree.ElementTree.parse`
   *
   * Given the following example:
   *
   * ```py
   * parser = lxml.etree.XMLParser()
   * xml.etree.ElementTree.fromstring(xml_content, parser=parser).text
   * ```
   *
   * * `this` would be `xml.etree.ElementTree.fromstring(xml_content, parser=parser)`.
   * * `getAnInput()`'s result would be `xml_content`.
   * * `vulnerable(kind)`'s `kind` would be `XXE`.
   */
  private class XMLEtreeParsing extends DataFlow::CallCfgNode, XML::XMLParsing::Range {
    XMLEtreeParsing() {
      this =
        API::moduleImport("xml")
            .getMember("etree")
            .getMember("ElementTree")
            .getMember(["fromstring", "fromstringlist", "XML", "parse"])
            .getACall()
    }

    override DataFlow::Node getAnInput() { result = this.getArg(0) }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      exists(XML::XMLParser xmlParser |
        xmlParser = this.getArgByName("parser").getALocalSource() and xmlParser.vulnerable(kind)
      )
    }
  }

  /**
   * A call to the `setFeature` method on a XML sax parser.
   *
   * See https://docs.python.org/3.10/library/xml.sax.reader.html#xml.sax.xmlreader.XMLReader.setFeature
   */
  class SaxParserSetFeatureCall extends DataFlow::MethodCallNode {
    SaxParserSetFeatureCall() {
      this =
        API::moduleImport("xml")
            .getMember("sax")
            .getMember("make_parser")
            .getReturn()
            .getMember("setFeature")
            .getACall()
    }

    // The keyword argument names does not match documentation. I checked (with Python
    // 3.9.5) that the names used here actually works.
    DataFlow::Node getFeatureArg() { result in [this.getArg(0), this.getArgByName("name")] }

    DataFlow::Node getStateArg() { result in [this.getArg(1), this.getArgByName("state")] }
  }

  /** Gets a back-reference to the `setFeature` state argument `arg`. */
  private DataFlow::TypeTrackingNode saxParserSetFeatureStateArgBacktracker(
    DataFlow::TypeBackTracker t, DataFlow::Node arg
  ) {
    t.start() and
    arg = any(SaxParserSetFeatureCall c).getStateArg() and
    result = arg.getALocalSource()
    or
    exists(DataFlow::TypeBackTracker t2 |
      result = saxParserSetFeatureStateArgBacktracker(t2, arg).backtrack(t2, t)
    )
  }

  /** Gets a back-reference to the `setFeature` state argument `arg`. */
  DataFlow::LocalSourceNode saxParserSetFeatureStateArgBacktracker(DataFlow::Node arg) {
    result = saxParserSetFeatureStateArgBacktracker(DataFlow::TypeBackTracker::end(), arg)
  }

  /** Gets a reference to a XML sax parser that has `feature_external_ges` turned on */
  private DataFlow::Node saxParserWithFeatureExternalGesTurnedOn(DataFlow::TypeTracker t) {
    t.start() and
    exists(SaxParserSetFeatureCall call |
      call.getFeatureArg() =
        API::moduleImport("xml")
            .getMember("sax")
            .getMember("handler")
            .getMember("feature_external_ges")
            .getAUse() and
      saxParserSetFeatureStateArgBacktracker(call.getStateArg())
          .asExpr()
          .(BooleanLiteral)
          .booleanValue() = true and
      result = call.getObject()
    )
    or
    exists(DataFlow::TypeTracker t2 |
      t = t2.smallstep(saxParserWithFeatureExternalGesTurnedOn(t2), result)
    ) and
    // take account of that we can set the feature to False, which makes the parser safe again
    not exists(SaxParserSetFeatureCall call |
      call.getObject() = result and
      call.getFeatureArg() =
        API::moduleImport("xml")
            .getMember("sax")
            .getMember("handler")
            .getMember("feature_external_ges")
            .getAUse() and
      saxParserSetFeatureStateArgBacktracker(call.getStateArg())
          .asExpr()
          .(BooleanLiteral)
          .booleanValue() = false
    )
  }

  /** Gets a reference to a XML sax parser that has been made unsafe for `kind`. */
  DataFlow::Node saxParserWithFeatureExternalGesTurnedOn() {
    result = saxParserWithFeatureExternalGesTurnedOn(DataFlow::TypeTracker::end())
  }

  /**
   * A XML parsing call with a sax parser.
   *
   * ```py
   * BadHandler = MainHandler()
   * parser = xml.sax.make_parser()
   * parser.setContentHandler(BadHandler)
   * parser.setFeature(xml.sax.handler.feature_external_ges, False)
   * parser.parse(StringIO(xml_content))
   * parsed_xml = BadHandler._result
   * ```
   */
  private class XMLSaxParsing extends DataFlow::MethodCallNode, XML::XMLParsing::Range {
    XMLSaxParsing() {
      this =
        API::moduleImport("xml")
            .getMember("sax")
            .getMember("make_parser")
            .getReturn()
            .getMember("parse")
            .getACall()
    }

    override DataFlow::Node getAnInput() { result = this.getArg(0) }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      // always vuln to these
      (kind.isBillionLaughs() or kind.isQuadraticBlowup())
      or
      // can be vuln to other things if features has been turned on
      this.getObject() = saxParserWithFeatureExternalGesTurnedOn() and
      (kind.isXxe() or kind.isDtdRetrieval())
    }
  }

  /**
   * Gets a call to:
   * * `lxml.etree.XMLParser`
   * * `lxml.etree.get_default_parser`
   *
   * Given the following example:
   *
   * ```py
   * lxml.etree.XMLParser()
   * ```
   *
   * * `this` would be `lxml.etree.XMLParser(resolve_entities=False)`.
   * * `vulnerable(kind)`'s `kind` would be `XXE`
   */
  private class LXMLParser extends DataFlow::CallCfgNode, XML::XMLParser::Range {
    LXMLParser() {
      this =
        API::moduleImport("lxml")
            .getMember("etree")
            .getMember(["XMLParser", "get_default_parser"])
            .getACall()
    }

    override DataFlow::Node getAnInput() { none() }

    // NOTE: it's not possible to change settings of a parser after constructing it
    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      kind.isXxe() and
      (
        // resolve_entities has default True
        not exists(this.getArgByName("resolve_entities"))
        or
        this.getArgByName("resolve_entities").getALocalSource().asExpr() = any(True t)
      )
      or
      (kind.isBillionLaughs() or kind.isQuadraticBlowup()) and
      (
        this.getArgByName("huge_tree").getALocalSource().asExpr() = any(True t) and
        not this.getArgByName("resolve_entities").getALocalSource().asExpr() = any(False f)
      )
    }
  }

  /**
   * Gets a call to:
   * * `lxml.etree.fromstring`
   * * `xml.etree.fromstringlist`
   * * `xml.etree.XML`
   * * `xml.etree.parse`
   *
   * Given the following example:
   *
   * ```py
   * parser = lxml.etree.XMLParser()
   * lxml.etree.fromstring(xml_content, parser=parser).text
   * ```
   *
   * * `this` would be `lxml.etree.fromstring(xml_content, parser=parser)`.
   * * `getAnInput()`'s result would be `xml_content`.
   * * `vulnerable(kind)`'s `kind` would be `XXE`.
   */
  private class LXMLParsing extends DataFlow::CallCfgNode, XML::XMLParsing::Range {
    LXMLParsing() {
      this =
        API::moduleImport("lxml")
            .getMember("etree")
            .getMember(["fromstring", "fromstringlist", "XML", "parse"])
            .getACall()
    }

    override DataFlow::Node getAnInput() { result = this.getArg(0) }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      exists(XML::XMLParser xmlParser |
        xmlParser = this.getArgByName("parser").getALocalSource() and xmlParser.vulnerable(kind)
      )
      or
      kind.isXxe() and not exists(this.getArgByName("parser"))
    }
  }

  /**
   * Gets a call to `xmltodict.parse`.
   *
   * Given the following example:
   *
   * ```py
   * xmltodict.parse(xml_content, disable_entities=False)
   * ```
   *
   * * `this` would be `xmltodict.parse(xml_content, disable_entities=False)`.
   * * `getAnInput()`'s result would be `xml_content`.
   * * `vulnerable(kind)`'s `kind` would be `Billion Laughs` and `Quadratic Blowup`.
   */
  private class XMLtoDictParsing extends DataFlow::CallCfgNode, XML::XMLParsing::Range {
    XMLtoDictParsing() { this = API::moduleImport("xmltodict").getMember("parse").getACall() }

    override DataFlow::Node getAnInput() { result = this.getArg(0) }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      (kind.isBillionLaughs() or kind.isQuadraticBlowup()) and
      this.getArgByName("disable_entities").getALocalSource().asExpr() = any(False f)
    }
  }

  /**
   * Gets a call to:
   * * `xml.dom.minidom.parse`
   * * `xml.dom.pulldom.parse`
   *
   * Given the following example:
   *
   * ```py
   * xml.dom.minidom.parse(StringIO(xml_content)).documentElement.childNode
   * ```
   *
   * * `this` would be `xml.dom.minidom.parse(StringIO(xml_content), parser=parser)`.
   * * `getAnInput()`'s result would be `StringIO(xml_content)`.
   * * `vulnerable(kind)`'s `kind` would be `Billion Laughs` and `Quadratic Blowup`.
   */
  private class XMLDomParsing extends DataFlow::CallCfgNode, XML::XMLParsing::Range {
    XMLDomParsing() {
      this =
        API::moduleImport("xml")
            .getMember("dom")
            .getMember(["minidom", "pulldom"])
            .getMember(["parse", "parseString"])
            .getACall()
    }

    override DataFlow::Node getAnInput() { result = this.getArg(0) }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      exists(XML::XMLParser xmlParser |
        xmlParser = this.getArgByName("parser").getALocalSource() and xmlParser.vulnerable(kind)
      )
      or
      (kind.isBillionLaughs() or kind.isQuadraticBlowup()) and
      not exists(this.getArgByName("parser"))
    }
  }

  /**
   * Gets a call to `xmlrpc.server.SimpleXMLRPCServer`.
   *
   * Given the following example:
   *
   * ```py
   * server = SimpleXMLRPCServer(("127.0.0.1", 8000))
   * server.register_function(foo, "foo")
   * server.serve_forever()
   * ```
   *
   * * `this` would be `SimpleXMLRPCServer(("127.0.0.1", 8000))`.
   * * `getAnInput()`'s result would be `foo`.
   * * `vulnerable(kind)`'s `kind` would be `Billion Laughs` and `Quadratic Blowup`.
   */
  private class XMLRPCServer extends DataFlow::CallCfgNode, XML::XMLParser::Range {
    XMLRPCServer() {
      this =
        API::moduleImport("xmlrpc").getMember("server").getMember("SimpleXMLRPCServer").getACall()
    }

    override DataFlow::Node getAnInput() {
      result = this.getAMethodCall("register_function").getArg(0)
    }

    override predicate vulnerable(XML::XMLVulnerabilityKind kind) {
      kind.isBillionLaughs() or kind.isQuadraticBlowup()
    }
  }
}
