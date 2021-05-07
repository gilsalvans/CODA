//sidebar functionality (using jQuery)
var Sidebar = (function () {
    function Sidebar(holder, eventElement, side, width, speed) { //sidebar constructor -> with its arguments
        this.side = side;
        this.width = width;
        this.speed = speed;
        this.holderId = $(holder);
        this.eventElementId = $(eventElement);
    }
    Sidebar.prototype.init = function () { //define its initialization function with respective parameters
        if (this.side != undefined) {
            if (this.side == 'left') { //sidebar side
                $(this.holderId).addClass('left');
            }
        }
        if (this.width != undefined) {
            $(this.holderId).css({ //define width 
                'max-width': this.width
            });
        }
        if (this.width != undefined) {
            $(this.holderId).css({ //define speed of opening sidebar (css parameter)
                'transition-duration': ((this.speed) / 1000) + 's'
            });
        }
        // attach click event
        this.clickEvent();
    }; 
    Sidebar.prototype.clickEvent = function () { //adding the clicking event function of the sidebar & buttons
        var holder = $(this.holderId);
        var elementBtn = $(this.eventElementId);
        var closeBtn = holder.find('a#sidebar-close');
        $(document).on('click', function (e) {
            var item = e.target;
            if ($(item).is(elementBtn)) {
                holder.addClass('active');
                return false;
            }
            else {
                if (!$(item).closest(holder).length || $(item).closest(closeBtn).length) {
                    if (holder.hasClass('active')) {
                        holder.removeClass('active');
                        return false;
                    }
                }
            }
        });
    };
    return Sidebar;
}());
;
window.onload = function () { //create sidebar object on loadig page with its specific arguments
    var sidebarLeft = new Sidebar('#sidebar', '#open-left', 'left', '45vh', 300);
    sidebarLeft.init();
};

//dropdown buttons to select each Telegram bot within the division
var dropdown = document.getElementsByClassName("dropdown-btn"); //get dropdown button elements
      
for (var i = 0; i < dropdown.length; i++) { //for each button
    dropdown[i].addEventListener("click", function() { //activation when clicking on it
    this.classList.toggle("active");
    var dropdownContent = this.nextElementSibling;

    if (dropdownContent.style.display === "block") { // do not display anything by default
        dropdownContent.style.display = "none";
    } 

    else {
        dropdownContent.style.display = "block";
    }
    });
} 
