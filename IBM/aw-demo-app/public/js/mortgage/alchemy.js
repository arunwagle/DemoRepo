'use strict';


$(document).ready(function() {
  var results = $('.results');
  var relations_template = relationsTemplate.innerHTML;
  var typed_relations_template = typedRelationsTemplate.innerHTML;

  $('.ml-item').click(function() {
    $('.1-result').hide();
    $('#div' + jQuery(this).attr('target')).show();
  });
  $('.ml-item').click(function() {
    $(this).addClass('ml-item-active');
    $(this).siblings().removeClass('ml-item-active');
  });

  $('.btn-results').click(function() {
    $('.add-1-result').toggle('fast');
    if ($.trim($(this).text()) === 'View top results') {
      $(this).addClass('arrowdown-main').removeClass('arrowup-main');
    } else {
      $(this).addClass('arrowup-main').removeClass('arrowdown-main');
    }
  });

  // relations main headings hide & expand actions
  $(document).ajaxComplete(function() {

    $('.header-relations').each(function() {
      $(this).text($(this).text().substr(0, 100) + '...');
    });

    if ($('.element-relations').length > 3) {
      $('.element-relations:gt(3)').hide();
    }

    if ($('.element-relations').length > 3) {
      $('.element-relations:gt(3)').hide();
    }
    if ($('.typedrelations').length > 1) {
      $('.typedrelations:gt(1)').hide();
    }


    if ($('.element-relations ').length < 3) {
      $('.btn-all-results-relations').hide();
    } else {
      $('.btn-all-results-relations').show();
    }

    if ($('.typedrelations').length < 2) {
      $('.btn-all-results-typedrelations').hide();
    } else {
      $('.btn-all-results-typedrelations').show();
    }

    $('.content-relations:first').css('display', 'block');
    $('.header-relations:first').addClass('arrowdown').removeClass('arrowup');

  });

  $('.btn-all-results-relations').click(function() {
    $('.element-relations:gt(3)').toggle('fast');
    if ($.trim($(this).text()) === 'View top results') {
      $(this).text('View all results');
    } else {
      $(this).text('View top results');
    }
  });

  $('.btn-all-results-typedrelations').click(function() {
    $('.typedrelations:gt(1)').toggle('fast');
    if ($.trim($(this).text()) === 'View top results') {
      $(this).text('View all results');
    } else {
      $(this).text('View top results');
    }
  });

  // hide & expand relations content
  $(document).ajaxComplete(function() {
    $('.header-relations').click(function() {
      $(this).toggleClass('arrowup arrowdown');
      $(this).siblings('.content-relations').toggle();
    });
  });


  $(document).ajaxComplete(function() {
    $('.output').show();
  });


  $('.tab-panels--tab').click(function(e) {
    e.preventDefault();
    var self = $(this);
    var inputGroup = self.closest('.tab-panels');
    var idName = null;

    inputGroup.find('.active').removeClass('active');
    self.addClass('active');
    idName = self.attr('href');
    $(idName).addClass('active');
  });

  // reset button code
  $('.reset').click(function() {
    location.reload();
  });



  $('#submitbutton').click(function() {
    // $(results).hide();
    $('.output').hide();
    $('#div1').show();
    $('#div2').hide();

    if ($('.tab-panels--tab.active').text() === 'Text') {
      callAPIswithText($('.input--text').val());
    } else {
      callAPIswithURL($('.input--URL').val());
    }
  });

  $('#saveToCloudant').click(function() {
    // console.log($('#relations-API-data').text());
    var selMenuItem = $('.ml-item.ml-item-active').text().trim();
    console.log("selMenuItem=" + selMenuItem);
    if(selMenuItem === "Relations"){
      console.log($('#relations-API-data').text());
      saveToCloudant($('#relations-API-data').text());
    }
    else{
      console.log($('#typedRelations-API-data').text());
      saveToCloudant($('#typedRelations-API-data').text());
    }
  });

  function saveToCloudant(text) {
    $.ajax({
      url: "/api/alchemy/saveToCloudant",
      type: "POST",
      cache: false,
      contentType: "application/json",
      dataType: "json",
      data: '{"result":' + text + '}'
    }).success(function() {
      console.log("Saved data to Cloudant");
    }).fail(_error);
  }

  function callAPIswithText(text) {
    getCombined(text);

  }

  function getCombined(text) {
    $.post('/api/alchemy/combined', {
      // entities,keywords,taxonomy,
      'extract': 'relations,typed-rels',
      'text': text
    }, function(data) {
      // console.log("data====" + JSON.stringify(data));
      $('.relations-table').html(_.template(relations_template, {
        items: data.relations
      }));

      $('#relations-API-data').empty();
      $('#relations-API-data').html(JSON.stringify(data.relations));

      $('.typedrelations-table').html(_.template(typed_relations_template, {
        items: data.typedRelations
      }));

      $('#typedRelations-API-data').empty();
      $('#typedRelations-API-data').html(JSON.stringify(data.typedRelations));

    }).fail(_error);
  }


  function _error(error) {
    $(results).hide();
    console.log(error);
  }



});
