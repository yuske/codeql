import java

module SpringDataRepository {
  private class FlowSummaries extends SummaryModelCsv {
    override predicate row(string row) {
      row = [
        "org.springframework.data.repository;CrudRepository;true;findAll;;;MapValue of Argument[-1];Element of ReturnValue;value",
        "org.springframework.data.repository;CrudRepository;true;findAllById;;;MapValue of Argument[-1];Element of ReturnValue;value",
        "org.springframework.data.repository;CrudRepository;true;findById;;;MapValue of Argument[-1];Element of ReturnValue;value",
        "org.springframework.data.repository;CrudRepository;true;save;;;Argument[0];MapValue of Argument[-1];value",
        "org.springframework.data.repository;CrudRepository;true;saveAll;;;Argument[0];MapValue of Argument[-1];value",
        "org.springframework.data.repository;PagingAndSortingRepository;true;findAll;;;MapValue of Argument[-1];Element of ReturnValue;value",
      ]
    }
  }
}
