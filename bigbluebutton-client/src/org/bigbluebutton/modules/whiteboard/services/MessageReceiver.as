/**
 * BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
 * 
 * Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
 *
 * This program is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 3.0 of the License, or (at your option) any later
 * version.
 * 
 * BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
 *
 */
package org.bigbluebutton.modules.whiteboard.services
{
  import org.as3commons.logging.api.ILogger;
  import org.as3commons.logging.api.getClassLogger;
  import org.bigbluebutton.core.BBB;
  import org.bigbluebutton.main.model.users.IMessageListener;
  import org.bigbluebutton.modules.whiteboard.models.Annotation;
  import org.bigbluebutton.modules.whiteboard.models.WhiteboardModel;

  public class MessageReceiver implements IMessageListener
  {
	private static const LOGGER:ILogger = getClassLogger(MessageReceiver);
    
        /* Injected by Mate */
    public var whiteboardModel:WhiteboardModel;
    
    public function MessageReceiver() {
      BBB.initConnectionManager().addMessageListener(this);
    }

    public function onMessage(messageName:String, message:Object):void {
      // trace("WB: received message " + messageName);

      switch (messageName) {
        case "WhiteboardRequestAnnotationHistoryReply":
          handleRequestAnnotationHistoryReply(message);
          break;
        case "WhiteboardIsWhiteboardEnabledReply":
          handleIsWhiteboardEnabledReply(message);
          break;
        case "WhiteboardEnableWhiteboardCommand":
          handleEnableWhiteboardCommand(message);
          break;    
        case "WhiteboardNewAnnotationCommand":
          handleNewAnnotationCommand(message);
          break;  
        case "WhiteboardClearCommand":
          handleClearCommand(message);
          break;  
        case "WhiteboardUndoCommand":
          handleUndoCommand(message);
          break;  			
        default:
//          LogUtil.warn("Cannot handle message [" + messageName + "]");
      }
    }

    private function handleClearCommand(message:Object):void {
      LOGGER.debug("*** handleClearCommand {0} **** \n", [message.msg]);      
      var map:Object = JSON.parse(message.msg);      
      
      LOGGER.debug("WB:MessageReceiver:Handle Whiteboard Clear Command ");
      if (map.hasOwnProperty("whiteboardId")) {
        whiteboardModel.clear(map.whiteboardId);
      }
      
    }

    private function handleUndoCommand(message:Object):void {
      LOGGER.debug("*** handleUndoCommand {0} **** \n", [message.msg]);      
      var map:Object = JSON.parse(message.msg);      
      if (map.hasOwnProperty("whiteboardId")) {
        whiteboardModel.undo(map.whiteboardId);
      }
    }

    private function handleEnableWhiteboardCommand(message:Object):void {
	  LOGGER.debug("*** handleEnableWhiteboardCommand {0} **** \n", [message.msg]);      

	  var map:Object = JSON.parse(message.msg);
            
      //if (result as Boolean) modifyEnabledCallback(true);
      // LogUtil.debug("Handle Whiteboard Enabled Command " + message.enabled);
      whiteboardModel.enable(map.enabled);
    }
    
    private function handleNewAnnotationCommand(message:Object):void {
      LOGGER.debug("*** handleNewAnnotationCommand {0} **** \n", [message.msg]);      
      var map:Object = JSON.parse(message.msg);
      var shape:Object = map.shape as Object;
      var an:Object = shape.shape as Object;
//      LOGGER.debug("*** handleNewAnnotationCommand shape id=[" + shape.id + "] type=[" + shape.type + "] status=[" + shape.status + "] **** \n"); 
      
      LOGGER.debug("*** handleNewAnnotationCommand an color=[{0}] thickness=[{1}] points=[{2}]**** \n", [an.color, an.thickness, an.points]);
//      LOGGER.debug("*** handleNewAnnotationCommand an a=[" + an + "] **** \n");
      
      var annotation:Annotation = new Annotation(shape.id, shape.type, an);
      annotation.status = shape.status;
      whiteboardModel.addAnnotation(annotation);
    }

    private function handleIsWhiteboardEnabledReply(message:Object):void {
      LOGGER.debug("*** handleIsWhiteboardEnabledReply {0} **** \n", [message.msg]);      
      var map:Object = JSON.parse(message.msg);
            
      //if (result as Boolean) modifyEnabledCallback(true);
	  LOGGER.debug("Whiteboard Enabled? {0}", [message.enabled]);
    }

    private function handleRequestAnnotationHistoryReply(message:Object):void {
      LOGGER.debug("*** handleRequestAnnotationHistoryReply {0} **** \n", [message.msg]);      
      var map:Object = JSON.parse(message.msg);      
   
      if (map.count == 0) {
        LOGGER.debug("handleRequestAnnotationHistoryReply: No annotations.");
      } else {
        LOGGER.debug("handleRequestAnnotationHistoryReply: Number of annotations in history = {0}", [map.count]);
        var annotations:Array = map.annotations as Array;
        var tempAnnotations:Array = new Array();
        
        for (var i:int = 0; i < map.count; i++) {
          var an:Object = annotations[i] as Object;
          var shape:Object = an.shapes as Object;                    
          var annotation:Annotation = new Annotation(an.id, an.type, shape);
          annotation.status = an.status;
          tempAnnotations.push(annotation);
        }   
                
        if (tempAnnotations.length > 0) {
          LOGGER.debug("Number of whiteboard shapes =[{0}]", [tempAnnotations.length]);
          whiteboardModel.addAnnotationFromHistory(map.whiteboardId, tempAnnotations);
        } else {
          LOGGER.debug("NO whiteboard shapes in history ");
        }
      }
    }
  }
}