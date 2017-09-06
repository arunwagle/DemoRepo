'use strict';

$(document).ready(function() {
  var results = $('.results');
  $('.results').hide();

  var entities_template = entitiesTemplate.innerHTML;
  var typedrelations_template = typedRelationsTemplate.innerHTML;
  // $('#div1').hide();
  // $('#div2').hide();


  var modelId = "937a4c50-7467-45cf-b08a-3c1ed98114ab";

  $('.ml-item').click(function() {
    $('.1-result').hide();
    $('#div' + jQuery(this).attr('target')).show();
    $(this).addClass('active');
    $(this).siblings().removeClass('active');
  });

  $('.btn-results').click(function() {
    $('.add-1-result').toggle('fast');
    if ($.trim($(this).text()) === 'View top results') {
      $(this).addClass('arrowdown-main').removeClass('arrowup-main');
    } else {
      $(this).addClass('arrowup-main').removeClass('arrowdown-main');
    }
  });

  // reset button code
  $('.reset').click(function() {
    location.reload();
  });

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

    if ($('.element-relations').length < 3) {
      $('.btn-all-results-relations').hide();
    } else {
      $('.btn-all-results-relations').show();
    }

    if ($('.typedrelations').length < 2) {
      $('.btn-all-results-typedrelations').hide();
    } else {
      $('.btn-all-results-typedrelations').show();
    }

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


  $(document).ajaxComplete(function() {
    $('.header-relations').click(function() {

        // hide & expand relations content
      $(this).toggleClass('arrowup arrowdown');
      $(this).siblings('.content-relations').toggle();
    });

    // Show first Relations result only
    $('.content-relations:first').css('display', 'block');
    $('.header-relations:first').addClass('arrowdown').removeClass('arrowup');

    $('.results').show();


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

  $('#submitbutton').click(function() {
    // $(results).hide();
    $('.results').hide();
    $('#div1').show();
    $('#div2').hide();

    if ($('.tab-panels--tab.active').text() === 'Text') {
      callAPIswithText($('.input--text').val());
    } else {
      callAPIswithURL($('.input--URL').val());
    }
  });

  function callAPIswithText(text) {
    getEntities(text);
    gettypedRelationsTyped(text);
  }

  function getEntities(text) {
    $.post('/api/alchemy/entities', {
      // entities,keywords,taxonomy,
      'model': modelId,
      'extract': 'relations,typed-rels',
      'sentiment': 1,
      'text': text
    }, function(data) {
      console.log("data====" + data);
      $('.entities-table').html(_.template(entities_template, {
        items: data.entities
      }));


      // $(results).show();
      // console.log("data =" + data)
      // $('#taxonomy-API-data').empty();
      // $('#taxonomy-API-data').html(JSON.stringify(data, null, 2));
    }).fail(_error);
  }

  function gettypedRelationsTyped(text) {
    var model = $('#model').val();
    $.post('/api/alchemy/typedRelations', {
      'text': text,
      'model': modelId,
      entities: 1,
      keywords: 1,
      arguments: 1
    }, function(data) {
      $('.typedrelations-table').html(_.template(typedrelations_template, {
        items: data.typedRelations
      }));
      // $('#typedrelations-API-data').empty();
      // $('#typedrelations-API-data').html(JSON.stringify(data, null, 2));
    }).fail(_error);
  }


  function _error(error) {
    $(results).hide();
    console.log(error);
  }

});
