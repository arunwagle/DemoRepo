
queue()
    .defer(d3.json, "/cf/cc/api/data")
    .defer(d3.json, "/cf/cc/api/ts/data")
    .await(renderAll)


function renderAll(error, rawData, tsData) {

//Start Transformations
  var rawDataSet = rawData;
  var tsDataSet = tsData;

  // Convert String to iso date format
  var dateFormat = d3.time.format.iso;
	tsDataSet.forEach(function(d) {
    // console.log("d  = " + d)
    // console.log("d.received_date = " + d.received_date)
		d.received_date = dateFormat.parse(d.received_date);
		d.received_date.setDate(1);
    // console.log("d.received_date formatted = " + d.received_date)
	});
// 2013-07-29T04:00:00.000Z

  // console.log("+++++rawDataSet:" + rawDataSet);
  // console.log("+++++tsDataSet:" + tsDataSet);
  //Create a Crossfilter instance
	var ndx = crossfilter(rawDataSet);

  // Create dataTable dimension
  var companyDimension = ndx.dimension(function (d) {
    return d.Company;
  });


  var dataTable = dc.dataTable('#dc-table-graph');


  dataTable
  .dimension(companyDimension)
  .size(5)
  .group(function(d) { return "<h4>Raw Sample Data</h4>"
	 })
  .columns([
      function (d) { return d.company },
      function (d) { return d.product },
      function (d) { return d.sub_product},
      function (d) { return d.issue },
      function (d) { return d.state }

  ]);


  // Render Time Series Data
  //Create a Crossfilter instance
	var tsNdx = crossfilter(tsDataSet);

  var complaintReceivedDate = tsNdx.dimension(function(d) { return d.received_date; });
  var company = tsNdx.dimension(function(d) { return d.company; });
  var product = tsNdx.dimension(function(d) { return d.product; });
  var issue = tsNdx.dimension(function(d) { return d.issue; });
  var complaintId = tsNdx.dimension(function(d) { return d.complaint_id; });

  // Grouping fields
  var complaintsByDate = complaintReceivedDate.group();
  var complaintsByCompany = company.group();
  var complaintsByProduct = product.group();
  var complaintsByIssue = issue.group();

	var all = tsNdx.groupAll();
  var year = tsNdx.dimension(function(d) { return d.year; });
  var yearGroup = year.group();

  //Define threshold values for data
  var minDate = complaintReceivedDate.bottom(1)[0].received_date;
  var maxDate = complaintReceivedDate.top(1)[0].received_date;

  // Charts
  var dateChart = dc.lineChart("#date-chart");
  var complaintsByCompanyChart = dc.rowChart("#complaints-by-companies-chart");
  var complaintsByProductChart = dc.rowChart("#complaints-by-product-chart");
  var complaintsByIssueChart = dc.rowChart("#complaints-by-issue-chart");
  var pieChart = dc.pieChart("#pie-chart");
  var pieChartProducts = dc.pieChart("#pie-chart-products");

  // Table
  var dataTable1 = dc.dataTable('#dc-table-graph-1');



  // year menu
  selectField = dc.selectMenu('#menuselect')
      .dimension(year)
      .group(yearGroup);

  dc.dataCount("#row-selection")
   .dimension(tsNdx)
   .group(all);

   console.log("minDate= " + minDate);
   console.log("maxDate= " + maxDate);
   dateChart
  		//.width(600)
  		.height(220)
  		.margins({top: 10, right: 50, bottom: 30, left: 50})
  		.dimension(complaintReceivedDate)
  		.group(complaintsByDate)
  		.renderArea(true)
  		.transitionDuration(500)
  		.x(d3.time.scale().domain([minDate, maxDate]))
  		.elasticY(true)
  		.renderHorizontalGridLines(true)
     	.renderVerticalGridLines(true)
  		.xAxisLabel("Year")
  		.yAxis().ticks(6);


    complaintsByCompanyChart
          //.width(300)
          .height(250)
          .dimension(company)
          .group(complaintsByCompany)
          .elasticX(true)
          .xAxis().ticks(5);

    complaintsByProductChart
          //.width(300)
          .height(250)
          .dimension(product)
          .group(complaintsByProduct)
          .elasticX(true)
          .xAxis().ticks(5);

    complaintsByIssueChart
          //.width(300)
          .height(1000)
          .dimension(issue)
          .group(complaintsByIssue)
          .elasticX(true)
          .xAxis().ticks(5);

    pieChart
      .height(450)
      //.width(350)
      .radius(200)
      .innerRadius(40)
      .transitionDuration(1000)
      .dimension(complaintId)
      .group(complaintsByCompany);

      pieChartProducts
        .height(450)
        // .width(450)
        .radius(200)
        .innerRadius(40)
        .transitionDuration(1000)
        .dimension(complaintId)
        .group(complaintsByProduct);


        var tableDimension    = tsNdx.dimension(function(d) {return [(+d.company),(+d.product)];})
        var tableGrouping = function (d) { return "<h5 style='color:green;'>" + d.company + "</h5>";};

        dataTable1
        .dimension(tableDimension)
        .size(10)
        .group(tableGrouping)
        .columns([
            function (d) { return d.product },
            function (d) { return d.issue },
            function (d) { return d.received_date }
        ])
        .sortBy(function (d) { return d.received_date; });


  dc.renderAll();

};
